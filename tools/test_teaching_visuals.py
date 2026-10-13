"""Regression checks for source-bound teaching visuals; no Azure operations."""
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import teaching_visuals as visuals


class SourceSynchronizationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.lesson = self.root/'lesson'
        self.lesson.mkdir()
        (self.lesson/'README.md').write_text('# Example\n',encoding='utf-8')
        self.source = self.lesson/'main.tf'
        self.source.write_text('resource "azurerm_resource_group" "lab" {\n name = local.prefix\n}\n',encoding='utf-8')
        self.item = {'Id':'CLZ-120','Folder':'lesson','DeploymentMode':'Azure deployment'}
        self.root_patch = patch.object(visuals,'ROOT',self.root)
        self.root_patch.start()
        self.addCleanup(self.root_patch.stop)

    def metadata(self):
        return visuals.source_metadata(self.item,('azurerm_resource_group.lab',),('name = local.prefix',))

    def test_normalizes_line_endings_for_portable_fingerprints(self):
        before = self.metadata()
        self.source.write_bytes(visuals.normalized_source(self.source).encode('utf-8').replace(b'\n',b'\r\n'))
        after = self.metadata()
        self.assertEqual(before['sourceFingerprints'],after['sourceFingerprints'])

    def test_resource_rename_rejects_stale_scene_inventory(self):
        self.source.write_text(self.source.read_text().replace('"lab"','"renamed"'),encoding='utf-8')
        with self.assertRaisesRegex(AssertionError,'illustrated resource absent'):
            self.metadata()

    def test_changed_connection_rejects_stale_teaching_arrow(self):
        self.source.write_text(self.source.read_text().replace('local.prefix','var.name'),encoding='utf-8')
        with self.assertRaisesRegex(AssertionError,'connection no longer exists'):
            self.metadata()

    def test_recursive_module_changes_are_fingerprinted(self):
        shared = self.root/'modules'/'shared'
        child = self.root/'modules'/'child'
        shared.mkdir(parents=True)
        child.mkdir()
        self.source.write_text(self.source.read_text()+'module "shared" { source = "../modules/shared" }\n',encoding='utf-8')
        (shared/'main.tf').write_text('module "child" { source = "../child" }\n',encoding='utf-8')
        child_tf = child/'main.tf'
        child_tf.write_text('locals { label = "first" }\n',encoding='utf-8')
        before = self.metadata()
        self.assertIn('modules/child/main.tf',before['sourceFiles'])
        child_tf.write_text('locals { label = "changed" }\n',encoding='utf-8')
        after = self.metadata()
        self.assertNotEqual(before['sourceSha256'],after['sourceSha256'])
        self.assertNotEqual(before['sourceFingerprints']['modules/child/main.tf'],after['sourceFingerprints']['modules/child/main.tf'])

    def test_local_lesson_cannot_silently_add_cloud_provider(self):
        self.item['Id'] = 'CLZ-100'
        self.source.write_text('provider "azurerm" { features {} }\n',encoding='utf-8')
        with self.assertRaisesRegex(AssertionError,'deployment boundary'):
            visuals.source_metadata(self.item,(),())

    def test_data_and_module_addresses_are_checked(self):
        self.source.write_text('data "terraform_remote_state" "shared" {}\nmodule "network" { source = "./network" }\n',encoding='utf-8')
        network = self.lesson/'network'
        network.mkdir()
        (network/'main.tf').write_text('locals {}\n',encoding='utf-8')
        result = visuals.source_metadata(self.item,('data.terraform_remote_state.shared','module.network'),())
        self.assertEqual(len(result['resourceInventory']),2)

    def test_missing_module_refuses_untraceable_topology(self):
        self.source.write_text(self.source.read_text()+'module "missing" { source = "../missing" }\n',encoding='utf-8')
        with self.assertRaisesRegex(AssertionError,'Missing local module'):
            self.metadata()


class DrawingContractTests(unittest.TestCase):
    def test_edges_attach_to_rectangle_boundaries(self):
        draw = visuals.Drawing()
        draw.node('a','A','plan',50,200)
        draw.node('b','B','cloud',450,200)
        draw.edge('a','b')
        self.assertIn('M240 275 L450 275',draw.paths[0])

    def test_oversized_content_fails_before_publishing(self):
        draw = visuals.Drawing()
        with self.assertRaisesRegex(AssertionError,'node'):
            draw.node('long','A long label that cannot fit in this tiny service card','plan',50,200,w=100,h=120,detail='More text')


if __name__=='__main__':
    unittest.main()
