PYTHON_DIR="/var/packages/python311/target/bin"
PACKAGE="rr-manager"
INSTALL_DIR="/usr/local/${PACKAGE}"
# PYTHON_DIR="/usr/local/bin/"
PATH="${SYNOPKG_PKGDEST}/env/bin:${SYNOPKG_PKGDEST}/bin:${SYNOPKG_PKGDEST}/usr/bin:${PYTHON_DIR}:${PATH}"
TMP_DIR="${SYNOPKG_PKGDEST}/../../@tmp"

service_postinst ()
{
    separator="===================================================="

    echo ${separator}
    install_python_virtualenv

    echo ${separator}
    install_python_wheels
    # /bin/sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db <${SYNOPKG_PKGDEST}/ui/createsqlitedata.sql

    echo ${separator}
    echo "Install packages to the app/libs folder"
    ${SYNOPKG_PKGDEST}/env/bin/pip install --target ${SYNOPKG_PKGDEST}/ui/libs/ -r ${SYNOPKG_PKGDEST}/share/wheelhouse/requirements.txt

    echo ${separator}
     if [ "${SYNOPKG_PKG_STATUS}" == "INSTALL" ]; then
        echo "Populate config.txt"
        sed -i -e "s|@this_is_upload_realpath@|${wizard_download_dir}|g" \
            -e "s|@this_is_sharename@|${wizard_download_share}|g" \
        "${SYNOPKG_PKGDEST}/ui/config.txt"
    fi
    exit 0
}

service_preupgrade ()
{
 # Save configuration files
    rm -fr ${TMP_DIR}/${PACKAGE}
    mkdir -p ${TMP_DIR}/${PACKAGE}

      # Save package config
    mv "${SYNOPKG_PKGDEST}/ui/config.txt" "${TMP_DIR}/${PACKAGE}/config.txt"
    exit 0
}

service_postupgrade ()
{
    rm -f "${SYNOPKG_PKGDEST}/ui/config.txt"
    # Restore package config
    mv "${TMP_DIR}/${PACKAGE}/config.txt" "${SYNOPKG_PKGDEST}/ui/config.txt"
    touch /tmp/rr_manager_installed
    rm -fr ${TMP_DIR}/${PACKAGE}
    exit 0
}

# Uninstall the package does not remove the tasks from the scheduler due to lack of permissions
service_postuninst ()
{
    echo "DELETE FROM task WHERE task_name='RunRrUpdate'" | sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db
    echo "DELETE FROM task WHERE task_name='ApplyRRConfig'" | sqlite3 /usr/syno/etc/esynoscheduler/esynoscheduler.db
    exit 0
}