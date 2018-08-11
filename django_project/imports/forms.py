# -*- coding: utf-8 -*-
from __future__ import absolute_import, division, print_function, unicode_literals

from django import forms

from .models import Task

from django.forms import ModelForm


class UploadFileForm(ModelForm):
    """Form for uploading file with data."""
    class Meta:
        model = Task
        fields = ('file',)


class InsertDataForm(forms.Form):
    """Form for inserting data from uploaded file."""
