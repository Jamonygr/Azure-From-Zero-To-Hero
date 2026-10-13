"use strict";

// Exercise the shipped scripts together with browser storage, fetch, and DOM
// boundaries. No Azure calls, third-party test packages, or production data.
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const test = require("node:test");
const root = path.resolve(__dirname, "../..");
const progressScript = fs.readFileSync(path.join(root, "docs/site-assets/progress.js"), "utf8");
const quizScript = fs.readFileSync(path.join(root, "docs/site-assets/quiz.js"), "utf8");
const key = "azureZeroToHeroLearnerProgress.v1";
const base = "https://example.test/Azure-From-Zero-To-Hero/";

class Element {
  constructor(tag, document) {
    this.tagName = tag.toLowerCase();
    this.document = document;
    this.children = [];
    this.dataset = {};
    this.attributes = {};
    this.listeners = {};
    this.className = "";
    this.value = "";
    this._text = "";
    this.classList = { add: (name) => { this.className += ` ${name}`; } };
  }
  get isConnected() { return this === this.document.body || Boolean(this.parentNode?.isConnected); }
  set textContent(value) { this._text = String(value); this.replaceChildren(); }
  get textContent() { return this._text + this.children.map((child) => child.textContent).join(""); }
  set innerHTML(value) {
    this.replaceChildren();
    const stack = [this];
    for (const token of value.match(/<[^>]+>|[^<]+/g) || []) {
      if (token.startsWith("</")) { stack.pop(); continue; }
      if (!token.startsWith("<")) { stack.at(-1)._text += token; continue; }
      const name = token.match(/^<([a-z0-9-]+)/i)?.[1];
      if (!name) continue;
      const element = this.document.createElement(name);
      for (const attribute of token.matchAll(/([a-z-]+)="([^"]*)"/g)) element.setAttribute(attribute[1], attribute[2]);
      stack.at(-1).append(element);
      if (!/^(input|br|img|meta)$/.test(name) && !token.endsWith("/>")) stack.push(element);
    }
  }
  append(...elements) {
    for (const element of elements) { element.parentNode = this; this.children.push(element); }
  }
  prepend(element) { element.parentNode = this; this.children.unshift(element); }
  replaceChildren(...elements) {
    for (const child of this.children) child.parentNode = null;
    this.children = [];
    this.append(...elements);
  }
  remove() {
    if (this.parentNode) this.parentNode.children = this.parentNode.children.filter((child) => child !== this);
    this.parentNode = null;
  }
  setAttribute(name, value) {
    this.attributes[name] = String(value);
    if (name === "id") this.id = String(value);
    if (name === "class") this.className = String(value);
    if (name.startsWith("data-")) this.dataset[name.slice(5).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] = String(value);
  }
  matches(selector) {
    const tag = selector.match(/^[a-z]+/i)?.[0];
    if (tag && tag !== this.tagName) return false;
    const id = selector.match(/#([a-z0-9-]+)/i)?.[1];
    if (id && id !== this.id) return false;
    const className = selector.match(/\.([a-z0-9-]+)/i)?.[1];
    if (className && !this.className.split(/\s+/).includes(className)) return false;
    const attribute = selector.match(/\[([a-z0-9-]+)(?:=['"]?([^'"\]]+)['"]?)?\]/i);
    if (attribute) {
      const name = attribute[1];
      const actual = name.startsWith("data-") ? this.dataset[name.slice(5).replace(/-([a-z])/g, (_, letter) => letter.toUpperCase())] : this[name] ?? this.attributes[name];
      if (actual === undefined || (attribute[2] !== undefined && actual !== attribute[2])) return false;
    }
    return !selector.endsWith(":checked") || this.checked === true;
  }
  querySelectorAll(selector) {
    const tokens = selector.split(/\s+/);
    const last = tokens.at(-1);
    const matches = [];
    const visit = (element) => {
      for (const child of element.children) {
        if (child.matches(last) && (tokens.length === 1 || child.parentNode.matches(tokens[0]))) matches.push(child);
        visit(child);
      }
    };
    visit(this);
    return matches;
  }
  querySelector(selector) { return this.querySelectorAll(selector)[0] || null; }
  addEventListener(name, callback) { (this.listeners[name] ||= []).push(callback); }
  async emit(name) { for (const callback of this.listeners[name] || []) await callback({ target: this }); }
  click() { return this.emit("click"); }
  focus() { this.document.activeElement = this; }
}

function record() {
  const timestamp = '2026-10-13T00:00:00.000Z';
  return {schemaVersion:'1.0.0',courseId:'azure-from-zero-to-hero',exportedAt:timestamp,
    labs:Object.fromEntries(Array.from({length:31},(_,i)=>[`CLZ-${String(90+i*10).padStart(3,"0")}`,{status:'not-started',exerciseComplete:false,cleanupComplete:false,assessmentScore:null,updatedAt:timestamp}]))};
}
function fixtures() {
  const labs=Array.from({length:30},(_,i)=>({labId:`CLZ-${100+i*10}`,title:`Lesson ${i+1}`,questionCount:30,bankUrl:`CLZ-${100+i*10}.json`,pathUrl:`labs/CLZ-${100+i*10}-example/`}));
  const banks=Object.fromEntries(labs.map(lab=>[lab.labId,{schemaVersion:'1.0.0',labId:lab.labId,pathUrl:lab.pathUrl,
    questions:Array.from({length:30},(_,i)=>({id:`${lab.labId}-Q${i+1}`,stem:`Question ${i+1} <script>alert(1)</script>`,options:{A:'Correct',B:'Wrong',C:'Third',D:'Fourth'},correctOption:'A',optionExplanations:{A:'Correct reason',B:'Wrong reason',C:'Third reason',D:'Fourth reason'},reviewUrl:lab.pathUrl+'#validate',sources:[{title:'Official',url:'https://developer.hashicorp.com/terraform/cli/commands/plan'}]}))}]));
  return {index:{schemaVersion:'1.0.0',labs},banks,catalog:{labs:[{labId:'CLZ-090',title:'Setup',pathUrl:'labs/CLZ-090-example/'},...labs]}};
}
function browser({initial=record(),page='practice/',fetcher,storageFailure=false}={}) {
  const document={readyState:'complete',currentScript:{src:base+'assets/progress.js'},addEventListener(){}};
  document.createElement=tag=>new Element(tag,document);
  document.body=document.createElement('body');
  document.querySelector=selector=>document.body.querySelector(selector);
  document.querySelectorAll=selector=>document.body.querySelectorAll(selector);
  if(page.startsWith('practice')) {
    const container=document.createElement('div');container.dataset.zthQuiz='';
    for(const [tag,id] of [['select','zth-quiz-lab'],['button','zth-quiz-load'],['button','zth-quiz-grade'],['p','zth-quiz-status'],['p','zth-quiz-count'],['div','zth-quiz-questions'],['div','zth-quiz-results']]) {const e=document.createElement(tag);e.id=id;container.append(e);}
    document.body.append(container);
  } else if(page.startsWith('learner-progress')) {
    const e=document.createElement('div');e.dataset.zthProgressDashboard='';document.body.append(e);
  } else if(page.startsWith('labs/')) {
    const e=document.createElement('div');e.dataset.zthLesson='CLZ-100';document.body.append(e);
  }
  const storage=new Map(initial===null?[]:[[key,JSON.stringify(initial)]]),downloads=[],requests=[],data=fixtures(),listeners={};
  class BrowserURL extends URL {static createObjectURL(blob){downloads.push(blob);return 'blob:test';} static revokeObjectURL(){}}
  const localStorage={getItem:name=>storage.get(name)??null,setItem:(name,value)=>{if(storageFailure)throw new Error('Storage full');storage.set(name,value);}};
  const context=vm.createContext({document,localStorage,URL:BrowserURL,Blob,AbortController,Event,
    location:{href:base+page},window:{location:{href:base+page},addEventListener:(name,fn)=>{(listeners[name]||=[]).push(fn);},dispatchEvent:event=>{for(const fn of listeners[event.type]||[])fn();}},
    fetch:async(url,options)=>{requests.push(String(url));if(fetcher)return fetcher(String(url),options,data);const value=String(url).endsWith('catalog.json')?data.catalog:String(url).endsWith('index.json')?data.index:data.banks[path.basename(String(url),'.json')];return {ok:true,json:async()=>value};}});
  vm.runInContext(progressScript,context);
  document.currentScript={src:base+'assets/quiz.js'};
  if(page.startsWith('practice'))vm.runInContext(quizScript,context);
  return {context,document,storage,downloads,requests,get:id=>document.querySelector('#'+id),saved:()=>JSON.parse(storage.get(key))};
}
async function settle(){for(let i=0;i<8;i++)await new Promise(resolve=>setImmediate(resolve));}
function answerAll(env,correct=30){env.get('zth-quiz-questions').querySelectorAll('fieldset').forEach((card,i)=>{card.querySelectorAll('input')[i<correct?0:1].checked=true;});}
test('lazy load one selected bank; 30 native groups render untrusted text safely',async()=>{const e=browser();await settle();assert.equal(e.requests.length,2);assert.equal(e.get('zth-quiz-lab').children.length,30);assert.equal(e.get('zth-quiz-questions').querySelectorAll('fieldset').length,30);assert.equal(e.get('zth-quiz-questions').querySelectorAll('script').length,0);assert.match(e.get('zth-quiz-questions').textContent,/<script>/);});
test('unanswered submissions preserve storage and focus first missing answer',async()=>{const e=browser();await settle();const before=e.storage.get(key);await e.get('zth-quiz-grade').click();assert.equal(e.storage.get(key),before);assert.match(e.get('zth-quiz-status').textContent,/30 remaining/);assert.equal(e.document.activeElement,e.get('zth-quiz-questions').querySelector('input'));});
test('mixed answers round the percentage and preserve every completion field',async()=>{const initial=record();Object.assign(initial.labs['CLZ-100'],{status:'complete',exerciseComplete:true,cleanupComplete:true});const e=browser({initial});await settle();answerAll(e,23);await e.get('zth-quiz-grade').click();assert.equal(e.saved().labs['CLZ-100'].assessmentScore,77);for(const field of ['status','exerciseComplete','cleanupComplete'])assert.equal(e.saved().labs['CLZ-100'][field],initial.labs['CLZ-100'][field]);assert.deepEqual(e.saved().labs['CLZ-110'],initial.labs['CLZ-110']);assert.equal(e.get('zth-quiz-questions').querySelectorAll('dd').length,120);assert.equal(e.get('zth-quiz-questions').querySelector('a').href,base+'labs/CLZ-100-example/#validate');const reload=browser({initial:e.saved(),page:'learner-progress/'});await settle();assert.match(reload.document.body.textContent,/quiz 77%/);});
test('all correct and all incorrect scores do not infer exercise completion',async()=>{for(const correct of [0,30]){const e=browser();await settle();answerAll(e,correct);await e.get('zth-quiz-grade').click();assert.equal(e.saved().labs['CLZ-100'].assessmentScore,correct===30?100:0);assert.equal(e.saved().labs['CLZ-100'].status,'not-started');}});
test('score updates read newer records and lesson controls preserve quiz results',async()=>{const e=browser({page:'labs/CLZ-100-example/'});e.context.window.zthProgress.saveAssessmentScore('CLZ-100',90);const newer=e.saved();newer.labs['CLZ-110'].assessmentScore=88;e.storage.set(key,JSON.stringify(newer));for(const text of ['Mark exercise complete','Mark cleanup complete / not applicable'])await e.document.body.querySelectorAll('button').find(b=>b.textContent===text).click();assert.equal(e.saved().labs['CLZ-100'].status,'complete');assert.equal(e.saved().labs['CLZ-100'].assessmentScore,90);assert.deepEqual(e.saved().labs['CLZ-110'],newer.labs['CLZ-110']);});
test('setup, invalid scores, and corrupt stored records are refused without replacement',()=>{const e=browser({page:'other/'}),save=e.context.window.zthProgress.saveAssessmentScore;assert.throws(()=>save('CLZ-090',80));for(const value of [-1,101,80.5,'80'])assert.throws(()=>save('CLZ-100',value));e.storage.set(key,JSON.stringify({...record(),token:'forbidden'}));const before=e.storage.get(key);assert.throws(()=>save('CLZ-100',90));assert.equal(e.storage.get(key),before);});
test('unavailable banks and unsafe remediation links preserve progress',async()=>{for(const invalid of [false,true]){const e=browser({fetcher:async(url,_o,data)=>{if(url.endsWith('index.json'))return {ok:true,json:async()=>data.index};if(!invalid)return {ok:false,status:503};data.banks['CLZ-100'].questions[0].reviewUrl='javascript:alert(1)';return {ok:true,json:async()=>data.banks['CLZ-100']};}});const before=e.storage.get(key);await settle();assert.match(e.get('zth-quiz-status').textContent,/could not be loaded/);assert.equal(e.get('zth-quiz-grade').disabled,true);assert.equal(e.storage.get(key),before);}});
test('storage failure still shows results without claiming persistence',async()=>{const e=browser({storageFailure:true});await settle();answerAll(e);await e.get('zth-quiz-grade').click();assert.match(e.get('zth-quiz-results').textContent,/100%/);assert.match(e.get('zth-quiz-status').textContent,/could not be saved/);});
test('late responses cannot replace a newly selected bank',async()=>{let release;const e=browser({fetcher:async(url,_o,data)=>{if(url.endsWith('index.json'))return {ok:true,json:async()=>data.index};if(url.endsWith('CLZ-100.json'))return new Promise(resolve=>{release=()=>resolve({ok:true,json:async()=>data.banks['CLZ-100']});});return {ok:true,json:async()=>data.banks['CLZ-110']};}});await settle();e.get('zth-quiz-lab').value='CLZ-110';await e.get('zth-quiz-lab').emit('change');release();await settle();assert.match(e.get('zth-quiz-status').textContent,/CLZ-110: Lesson 2/);});
test('valid import/export round trips the version 1 course format',async()=>{const e=browser({page:'learner-progress/'});await settle();const imported=record();imported.labs['CLZ-390'].assessmentScore=87;const file=e.document.querySelector("input[type='file']");file.files=[{size:9000,text:async()=>JSON.stringify(imported)}];await file.emit('change');assert.deepEqual(e.saved(),imported);await e.document.body.querySelectorAll('button').find(b=>b.textContent==='Export progress JSON').click();const exported=JSON.parse(await e.downloads[0].text());assert.deepEqual(exported,e.saved());});
test('invalid, wrong-course, oversized imports leave existing progress untouched',async()=>{for(const invalid of [{...record(),courseId:'other'},{...record(),token:'forbidden'},{...record(),schemaVersion:'2.0.0'},null]){const e=browser({page:'learner-progress/'});await settle();const before=e.storage.get(key),file=e.document.querySelector("input[type='file']");file.files=[{size:invalid===null?256*1024+1:9000,text:async()=>JSON.stringify(invalid)}];await file.emit('change');assert.equal(e.storage.get(key),before);assert.match(e.document.body.textContent,/Import refused/);}});
