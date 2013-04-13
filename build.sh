#!/bin/bash

build_dir="${TMPDIR}cultuurnet";

current_dir=$PWD

rm -Rf $build_dir;
mkdir $build_dir;

cd $build_dir;

drush make -y --drupal-org=core "${current_dir}/drupal-org-core.make";

ls -al;

mkdir profiles/cultuurnet;
cp -R "${current_dir}"/* ./profiles/cultuurnet/;

cd profiles/cultuurnet;

# The following currently does not work as drupal.org does not allow
# to include modules not hosted on git.drupal.org
#drush make -y --drupal-org=contrib "${current_dir}/drupal-org.make";

drush make -y --no-core "${current_dir}/drupal-org.make";
mv sites/all/* ./
rm -Rf sites

cd $build_dir;

# Copy over composer.json and composer.lock.
cp "${current_dir}/support/composer."* .;

# Install dependencies with composer.
composer install;

cd ${current_dir};

echo "build is available in ${build_dir}.";

exit;
