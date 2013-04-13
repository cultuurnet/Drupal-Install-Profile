<?php

/**
 * @file
 *
 */

/**
 * Implements hook_install_tasks().
 */
function cultuurnet_install_tasks(&$install_state) {
  $tasks = array();

  $tasks['cultuurnet_credentials_form'] = array(
    'display_name' => st('CultuurNet credentials'),
    'display' => TRUE,
    'type' => 'form',
  );

  return $tasks;
}

function cultuurnet_credentials_form($form, &$form_state, &$install_state) {
  drupal_set_title(st('CultuurNet credentials'));

  // @todo Get defaults from a webservice in the previous step?
  $defaults = array();
  $defaults += array(
    'culturefeed_api_application_key' => '76163fc774cb42246d9de37cadeece8a',
    'culturefeed_api_shared_secret' => 'fff975c5a8c7ba19ce92969c1879b211',
    'cnapi_api_key' => 'AEBA59E1-F80E-4EE2-AE7E-CEDD6A589CA9',
    'cnapi_api_location' => 'http://build.uitdatabank.be/',
    'cnapi_lib_version' => '1.1',
    'cnapi_output_type' => '1',
  );

  $form['culturefeed'] = array(
    '#type' => 'fieldset',
    '#title' => t('CultureFeed'),
  );

  $form['culturefeed']['culturefeed_api_application_key'] = array(
    '#title' => t('Consumer key'),
    '#type' => 'textfield',
    '#default_value' => $defaults['culturefeed_api_application_key'],
    '#required' => TRUE,
  );

  $form['culturefeed']['culturefeed_api_shared_secret'] = array(
    '#title' => t('Consumer secret'),
    '#type' => 'textfield',
    '#default_value' => $defaults['culturefeed_api_shared_secret'],
    '#required' => TRUE,
  );

  $form['cnapi'] = array(
    '#type' => 'fieldset',
    '#title' => t('Cnapi'),
  );

  $form['cnapi']['cnapi_api_location'] = array(
    '#title' => t('API location'),
    '#type' => t('textfield'),
    '#default_value' => $defaults['cnapi_api_location'],
    '#description' => t('The URL where the CultuurNet API resides. End with a slash. Example: http://build.uitdatabank.be/'),
    '#element_validate' => array('cultuurnet_cnapi_api_location_validate'),
  );

  $form['cnapi']['cnapi_api_key'] = array(
    '#title' => t('API key'),
    '#type' => 'textfield',
    '#default_value' => $defaults['cnapi_api_key'],
    '#required' => TRUE,
    '#description' => t('Your CultuurNet API key'),
  );

  $form['cnapi']['cnapi_output_type'] = array(
    '#title' => t('Output type'),
    '#type' => 'textfield',
    '#default_value' => $defaults['cnapi_output_type'],
    '#description' => t('Your CultuurNet API output type.'),
  );

  $form['cnapi']['cnapi_lib_version'] = array(
    '#title' => t('Library version'),
    '#type' => 'select',
    '#description' => t('Version identifier of the values XML files.'),
    '#options' => array(
      '1.1' => '1.1',
    ),
    '#default_value' => $defaults['cnapi_lib_version'],
  );

  $form['submit'] = array(
    '#type' => 'submit',
    '#value' => t('Continue'),
  );

  return $form;
}

function cultuurnet_credentials_form_submit($form, &$form_state) {
  $fieldsets = array('cnapi', 'culturefeed');
  foreach ($fieldsets as $fieldset) {
    $children = element_children($form[$fieldset]);

    foreach ($children as $child) {
      variable_set($child, $form_state['values'][$child]);
    }
  }

  // For debugging purposes.
  // Can be replaced with any other kind of log module after installation.
  module_enable(array('dblog'));
}

function cultuurnet_cnapi_api_location_validate($element, &$form_state, $form) {
  if (!valid_url($element['#value'], TRUE)) {
    return form_error($element, t('!name needs to be a valid URL.', array('!name' => $element['title'])));
  }

  if (drupal_substr($element['#value'], -1) !== '/') {
    return form_error($element, t('!name needs to end with a slash.', array('!name' => $element['title'])));
  }
}
