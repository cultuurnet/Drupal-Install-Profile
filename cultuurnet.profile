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
    'display_name' => t('CultuurNet credentials'),
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
    'culturefeed_api_application_key' => '',
    'culturefeed_api_shared_secret' => '',
    'cnapi_api_key' => '',
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

  $form['cnapi']['cnapi_api_key'] = array(
    '#title' => t('API key'),
    '#type' => 'textfield',
    '#default_value' => $defaults['cnapi_api_key'],
    #required' => TRUE,
  );
}


