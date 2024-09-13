#!/bin/bash -e
sed -i "s/mime-support,//g" debian/control
sed -i "s/libtiff5,//g" debian/control
