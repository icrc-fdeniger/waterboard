# coding=utf-8
"""Send sms alert."""

__author__ = 'Christian Christelis <christian@kartoza.com>'
__project_name = 'watchkeeper'
__date__ = '8/05/15'
__copyright__ = 'kartoza.com'
__doc__ = ''

from celery import shared_task

from django.core.mail import send_mail

from notifications.models import Notification


@shared_task
def send_email_message(user, text_message, html_message):
    send_mail(
        'immap',
        text_message,
        'alert@immap.kartoza.com',
        [user.email],
        fail_silently=False,
        html_message=html_message)
    notification = Notification(
        alert_type='email',
        recipient=user,
        message_content=text_message)
    notification.save()
