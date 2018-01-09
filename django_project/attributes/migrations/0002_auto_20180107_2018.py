# -*- coding: utf-8 -*-
# Generated by Django 1.11.8 on 2018-01-07 19:18
from __future__ import unicode_literals

from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('attributes', '0001_initial'),
    ]

    operations = [
        migrations.CreateModel(
            name='ChoiceAttribute',
            fields=[
            ],
            options={
                'proxy': True,
                'indexes': [],
            },
            bases=('attributes.attribute',),
        ),
        migrations.CreateModel(
            name='SimpleAttribute',
            fields=[
            ],
            options={
                'proxy': True,
                'indexes': [],
            },
            bases=('attributes.attribute',),
        ),
        migrations.RenameField(
            model_name='attribute',
            old_name='name',
            new_name='label',
        ),
        migrations.RenameField(
            model_name='attributegroup',
            old_name='name',
            new_name='label',
        ),
        migrations.AddField(
            model_name='attribute',
            name='key',
            field=models.CharField(default='', help_text='internal key of the attribute', max_length=32, unique=True),
            preserve_default=False,
        ),
        migrations.AlterField(
            model_name='attribute',
            name='result_type',
            field=models.CharField(choices=[('Integer', 'Integer'), ('Decimal', 'Decimal'), ('Text', 'Text'), ('DropDown', 'DropDown'), ('MultipleChoice', 'MultipleChoice')], max_length=16),
        ),
        migrations.AlterField(
            model_name='attributeoption',
            name='description',
            field=models.TextField(blank=True),
        ),
    ]
