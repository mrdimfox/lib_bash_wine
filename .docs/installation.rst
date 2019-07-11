Prerequisites:
    - Ubuntu xenial, bionic, disco or newer
    - xvfb Service installed and running for headless machines


.. code-block:: bash

    # local installation
    sudo apt-get install git
    sudo git clone https://github.com/bitranox/lib_bash_wine.git /usr/local/lib_bash_wine
    sudo chmod -R 0755 /usr/local/lib_bash_wine
    sudo chmod -R +x /usr/local/lib_bash_wine/*.sh
    sudo /usr/local/lib_bash_wine/install_or_update_lib_bash_wine.sh
