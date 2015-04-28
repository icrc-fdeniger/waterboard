# coding=utf-8
"""Custom User Manager for user of Watchkeeper."""
__author__ = 'ismailsunni'
__project_name = 'watchkeeper'
__filename = 'user_manager'
__date__ = '4/28/15'
__copyright__ = 'imajimatika@gmail.com'
__doc__ = ''


from django.contrib.gis.db.models import GeoManager
from django.contrib.auth.models import BaseUserManager


class CustomUserManager(BaseUserManager, GeoManager):
    """Custom UserManager for event_mapper."""
    class Meta:
        """Meta class."""
        app_label = 'event_mapper'

    def create_user(
            self,
            email,
            first_name,
            last_name,
            phone_number='',
            notified=False,
            area_of_interest=None,
            password=None):
        if not email:
            raise ValueError('User must have email.')

        user = self.model(
            email=self.normalize_email(email),
            first_name=first_name,
            last_name=last_name,
            phone_number=phone_number,
            notified=notified,
            area_of_interest=area_of_interest,
        )

        user.set_password(password)
        user.save(using=self._db)

        return user

    def create_superuser(
            self, first_name, last_name, email, password):
        """Create and save superuser
        :param first_name:
        :param last_name:
        :param email:
        :return:
        """
        user = self.create_user(
            first_name=first_name,
            last_name=last_name,
            email=email,
            password=password,
        )

        user.phone_number = ''
        user.is_confirmed = True
        user.is_active = True
        user.is_admin = True
        user.save(using=self._db)

        return user
