# Generated by Django 2.1.8 on 2019-06-02 12:45

import django.contrib.auth.validators
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('webusers', '0007_auto_20190602_1423'),
    ]

    operations = [
        migrations.AlterField(
            model_name='webuser',
            name='email',
            field=models.EmailField(blank=True, help_text='Please enter your email address. This will also be your login name.', max_length=254, null=True, verbose_name='Email'),
        ),
        migrations.AlterField(
            model_name='webuser',
            name='full_name',
            field=models.CharField(blank=True, help_text='Your full name.', max_length=100, null=True, verbose_name='Full name'),
        ),
        migrations.AlterField(
            model_name='webuser',
            name='username',
            field=models.CharField(error_messages={'unique': 'A user with that username already exists.'}, help_text='Required. 150 characters or fewer. Letters, digits and @/./+/-/_ only.', max_length=150, unique=True, validators=[django.contrib.auth.validators.UnicodeUsernameValidator()], verbose_name='Username'),
        ),
    ]
