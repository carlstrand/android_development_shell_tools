#!/bin/bash
TimeStart=$(date +%s);

# BasketBuild Upload Credentials
export UploadUserName='Username.s';
export UploadPassword='';

# Create  ~/.bash_android.basketbuild.**name**.rc with the exports to override the credentials
RemoteVariant="${3}";
if [ ! -z "${RemoteVariant}" ] && [ -f ~/.bash_android.basketbuild.${RemoteVariant}.rc ]; then
  source ~/.bash_android.basketbuild.${RemoteVariant}.rc;
elif [ -f ~/.bash_android.basketbuild.main.rc ]; then
  source ~/.bash_android.basketbuild.main.rc;
fi;

# Variables
SendFile="${1}";
UploadFolder="${2:-Development}";

# Notify and verify the upload
echo '';
echo -e " \e[1;33m[ Uploading to the server - User '${UploadUserName}' - Path '${UploadFolder}' ]\e[0m";
echo '';
if [ ! -z "${SendFile}" ] && [ -f "${SendFile}" ] && [ ! -z "${UploadPassword}" ]; then

  # File variables
  SendFileName=$(basename "${SendFile}");
  SendFileExt=${SendFileName##*.};
  SendFileSize=$(stat -c "%s" "${SendFile}");
  SendFileType='';

  # Uploading a zip
  if [[ "${SendFileExt}" =~ 'zip' ]]; then
    SendFileType='application/zip';
  fi;

  # Notify the file name
  echo "   File '$(basename ${SendFile})' uploading...";
  echo '';

  # Upload to BasketBuild through FTP
  ncftpput -R -v -t 10 \
           -u "${UploadUserName}" \
           -p "${UploadPassword}" \
           'basketbuild.com' \
           ${UploadFolder} \
           ${SendFile};

  # Detect failed FTP upload
  if [ ${?} -ne 0 ]; then

    # Fallback to WebUI upload
    notify-send "Failed uploading through FTP...";
    echo '';
    echo '   Failed uploading through FTP. Falling back to WebUI upload...';
    echo '';

    # Login to BasketBuild
    curl -L -# --dump-header .headers \
            -F "ftp_user=${UploadUserName}" \
            -F "ftp_pass=${UploadPassword}" \
            -F "openFolder=~${UploadFolder}" \
            -F "ip_check=1" \
            -F "login=1" \
            -F "login_save=1" \
            -F "submit=Login" \
            'https://s.basketbuild.com/webupload/' > /dev/null;

    # Upload to BasketBuild through WebUI
    curl -X POST -L -# --progress-bar -b .headers \
            -H "Cache-Control: no-cache" \
            -H "X-Filename: ${SendFileName}" \
            -H "X-Requested-With: XMLHttpRequest" \
            -H "X-File-Size: ${SendFileSize}" \
            -H "X-File-Type: ${SendFileType}" \
            -H "Content-Type: multipart/form-data" \
            --data-binary @"${SendFile}" \
            -o .uploadoutputs \
            'https://s.basketbuild.com/webupload/?ftpAction=upload&filePath=';

  fi;

  # Upload done
  echo '';
  echo -e "  \e[1;32mDownload :\e[0m https://basketbuild.com/filedl/devs?dev=${UploadUserName:0:-2}&dl=${UploadUserName:0:-2}/${UploadFolder}/${SendFileName} ";

  # Clean curl files
  rm -f ./.headers ./.uploadoutputs;

# Credentials missing
elif [ -z "${UploadPassword}" ]; then
  echo '  FTP Credentials not found...';

# File missing
else
  echo "  File '${SendFile}' not found...";
fi;

# Upload timing
TimeDiff=$(($(date +%s)-${TimeStart}));
echo '';
echo -e " \e[1;37m[ Done in ${TimeDiff} secs ]\e[0m";
echo '';
