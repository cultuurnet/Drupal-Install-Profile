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

  $tasks['cultuurnet_cnapi_import_values'] = array(
    'display_name' => st('Import CultuurNet values'),
    'display' => TRUE,
    'type' => 'batch',
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

/**
 * Batch callback function for importing cnapi values.
 *
 * @param $context
 *   The batch API context.
 */
function cultuurnet_cnapi_import_values_batch(&$context) {
  if (empty($context['sandbox'])) {
    $context['sandbox']['progress'] = 0;
    $context['sandbox']['max'] = 9;
    $context['results']['errors'] = array();
  }

  module_load_include('inc', 'cnapi', 'cnapi.import');

  $t = get_t();

  try {
  switch ($context['sandbox']['progress']) {

    case 0:
      $title = $t('Imported output types.');
      // output types
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_OUTPUT_TYPE,
        '/Output_type/row',
        array(
          'tid'              => array('path' => '@id', 'parser' => 'intval'),
          'name'             => array('path' => '@title', 'parser' => 'strval'),
          'region_dimension' => array('path' => '@dimension_region', 'parser' => 'strval'),
        ),
        'cnapi_output_type'
      );
      break;

    case 1:
      // dimensions
      $title = $t('Imported dimensions.');
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_DIMENSION,
        '/Dimension/dimension',
        array(
          'did'         => array('path' => '@id', 'parser' => 'intval'),
          'machinename' => array('path' => '@value', 'parser' => 'strval'),
          'name'        => array('path' => '@label', 'parser' => 'strval'),
        ),
        'cnapi_dimension'
      );
      break;

    case 2:
      $title = $t('Imported categories.');
      // categories
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_CATEGORISATION,
        '/Categorisation/categorisation',
        array(
          'cid'   => array('path' => '@cnet_id', 'parser' => 'strval'),
          'name'  => array('path' => '@title', 'parser' => 'strval'),
          'did'   => array('path' => '@dimension', 'parser' => 'intval'),
        ),
        'cnapi_category'
      );
      break;

    case 3:
      $title = $t('Imported headings.');
      // headings
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_HEADING,
        '/Heading/heading',
        array(
          'hid'    => array('path' => '@id', 'parser' => 'intval'),
          'pid'    => array('path' => '@parent_id', 'parser' => 'strval'),
          'weight' => array('path' => '@sort', 'parser' => 'intval'),
          'name'   => array('path' => '@title', 'parser' => 'strval'),
          'tid'    => array('path' => '@output_type_id', 'parser' => 'strval'),
        ),
        'cnapi_heading'
      );
      break;

    case 4:
      $title = $t('Imported cities.');
      // cities
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_CITY, '/City/city',
        array(
          'lid'   => array('path' => '@id', 'parser' => 'strval'),
          'type'  => 'city',
          'name'  => array('path' => '@city', 'parser' => 'strval'),
          'zip'   => array('path' => '@zip', 'parser' => 'strval'),
          'did'   => 0,
        ),
        'cnapi_location'
      );
      break;

    case 5:
      $title = $t('Imported cities hierarchy.');
      // cities hierarchy
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_CITY,
        '/City/city',
        array(
          'lid' => array('path' => '@id', 'parser' => 'strval'),
          'pid' => array('path' => '@parent', 'parser' => 'strval'),
        ),
        'cnapi_location_hierarchy'
      );
      break;

    case 6:
      $title = $t('Imported regions.');
      // regions
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_REGION,
        '/Region/region',
        array(
          'lid'   => array('path' => '@id', 'parser' => 'strval'),
          'type'  => 'region',
          'name'  => array('path' => '@title', 'parser' => 'strval'),
          'zip'   => NULL,
          'did'   => array('path' => '@dimension', 'parser' => 'intval'),
        ),
        'cnapi_location',
        array(),
        FALSE
      );
      break;

    case 7:
      $title = $t('Imported regions hierarchy.');
      // regions hierarchy
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_REGION,
        '/Region/region',
        array(
          'lid'       => array('path' => '@id', 'parser' => 'strval'),
          'pid'       => array('path' => 'parents/@parent', 'parser' => 'strval'),
        ),
        'cnapi_location_hierarchy',
        array(),
        FALSE,
        'pid'
      );
      break;

    case 8:
      $title = $t('Imported city - regions hierarchy.');
      // city - regions hierarchy
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_CITY_REGION,
        '/City_region/city_region',
        array(
          'lid' => array('path' => '@id', 'parser' => 'strval'),
          'pid' => array('path' => '@region_id', 'parser' => 'strval'),
        ),
        'cnapi_location_hierarchy',
        array(),
        FALSE
      );
      break;

    case 9:
      $title = $t('Imported heading categorisation.');
      // heading categorisation
      cultuurnet_cnapi_xml_values_import(
        CNAPI_XML_HEADING_CATEGORISATION,
        '/Heading_categorisation/heading_categorisation',
        array(
          'hid' => array('path' => '@heading_id', 'parser' => 'intval'),
          'cid' => array('path' => '@cnet_id', 'parser' => 'strval'),
        ),
        'cnapi_heading_category'
      );
      break;
  }
  }
  catch (Exception $e) {
    $context['results']['errors'][] = $e->getMessage();
  }

  $context['sandbox']['progress']++;

  $context['message'] = check_plain($title);

  if ($context['sandbox']['progress'] != $context['sandbox']['max']) {
    $context['finished'] = $context['sandbox']['progress'] / $context['sandbox']['max'];
  }
}

function cultuurnet_cnapi_xml_values_import($file, $path, $mappings, $table, $primary_key = array(), $truncate = TRUE, $multiple_key = '') {
  $file = cultuurnet_cnapi_xml_values_file($file);
  _cultuurnet_cnapi_xml_values_import($file, $path, $mappings, $table, $primary_key, $truncate, $multiple_key);
}

function cultuurnet_cnapi_import_values(&$install_state) {
  $operations = array();

  $operations[] = array('cultuurnet_cnapi_import_values_batch', array());

  // @todo add actor import

  $batch = array(
    'title' => t('Importing CultuurNet values'),
    'finished' => 'cultuurnet_cnapi_import_finished',
    'operations' => $operations,
  );

  return $batch;
}

function cultuurnet_cnapi_import_finished($success, $results, $operations) {
  cache_clear_all();

  foreach ($results['errors'] as $error) {
    drupal_set_message($error, 'error');
  }
}

/**
 * Optimized version of _cnapi_xml_import().
 *
 * To reduce HTTP requests, the xml files need to be downloaded and cached locally first with
 * cultuurnet_cnapi_xml_values_file(), then pass the returned path to this method.
 *
 * @param $path
 *   The XPath path that represents the nodes to be imported as individual rows in the destination table.
 * @param $mapping
 *   An associative array representing the mappings of all fields. The key of each row in the array represents the field name of the local table. The value of each row is an associative array having keys 'path' and 'parser'. The value of 'path' is the XPath path relative to a node from $path. The value of 'parser' is the function (intval, strval, ...) that should be used to transform the SimpleXML element to a value.
 * @param $table
 *   The table to import the elements in.
 * @param $primary_key
 *   The primary key of the table as is should be used in drupal_write_record.
 * @param $truncate
 *   A boolean indicating wether the table should be truncated before importing.
 * @param $multiple_key
 *   If an item represented as node in the XML document should be multiplexed into multiple rows in the local table, $multiple_key indicated what Xpath path should used to indicate the multiple values.
 *
 *
 */
function _cultuurnet_cnapi_xml_values_import($file, $path, $mappings, $table, $primary_key = array(), $truncate = TRUE, $multiple_key = '') {
  $xml = file_get_contents($file);

  if ($xml && $xml = new SimpleXMLElement($xml)) {
    // truncate the table if necessary
    if ($truncate) {
      db_truncate($table)->execute();
    }

    // iterate over all xml nodes represented by $path
    foreach ($xml->xpath($path) as $row) {
      $object = array();
      foreach ($mappings as $id => $mapping) {
        if (is_array($mapping)) {
          $value = $row->xpath($mapping['path']);
          if (isset($value[0])) {
            $object[$id] = trim(call_user_func($mapping['parser'], $value[0]));
          }
        }
        else {
          $object[$id] = $mapping;
        }
      }

      $objects = array();

      if (empty($multiple_key)) {
        $objects[] = $object;
      }
      else {
        $values = $row->xpath($mappings[$multiple_key]['path']);
        foreach ($values as $value) {
          $object[$multiple_key] = trim(call_user_func($mappings[$multiple_key]['parser'], $value));
          $objects[] = $object;
        }
      }

      foreach ($objects as $object) {
        if ($table == 'cnapi_location_hierarchy' && empty($object['pid'])) {
          continue;
        }
        drupal_write_record($table, $object, $primary_key);
      }
    }
  }
  else {
    watchdog('cnapi', 'An error occured while importing values.', array(), WATCHDOG_ERROR);
    return;
  }
}

/**
 *
 * @param string $file
 * @param bool $reset
 *
 * @return Path to a local copy of the file.
 */
function cultuurnet_cnapi_xml_values_file($file, $reset = FALSE) {
  $base_url = rtrim(variable_get('cnapi_api_location', CNAPI_API_LOCATION), '/');
  $version = variable_get('cnapi_lib_version', '');

  $url = "{$base_url}/lib/{$version}/{$file}";

  $directory = 'public://cultuurnet/lib/' . $version;
  $destination = $directory . '/' . $file;

  if (!$reset && file_exists($destination)) {
    return $destination;
  }

  $response = drupal_http_request($url);

  if ($response->code != 200) {
    throw new Exception('Failed downloading ' . $url);
  }

  file_prepare_directory($directory, FILE_CREATE_DIRECTORY | FILE_MODIFY_PERMISSIONS);
  file_unmanaged_save_data($response->data, $destination, FILE_EXISTS_REPLACE);

  return $destination;
}
