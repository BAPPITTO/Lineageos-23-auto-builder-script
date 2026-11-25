#!/usr/bin/env bash
# =============================================================================
# sign_pls.sh – Signed LineageOS build helper
# =============================================================================
# Generates Android signing keys (platform + APEX), builds target-files,
# signs them and produces a signed OTA package.
#
# Usage (normally called by the main builder):
#   ./sign_pls.sh <email>
#   or interactively (will ask for missing data)
#
# MIT License
#
# Copyright (c) 2026 Dudu-gsh
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# =============================================================================

set -euo pipefail

# ---------------------------------------------------------------------------
# Globals (filled by prompts / arguments)
# ---------------------------------------------------------------------------
EMAIL="${1:-}"
NAME=""
CODENAME=""
SUBJECT=""
USE_PASSWORD=""

CERTS_DIR="${HOME}/.android-certs"

# List of classic keys that make_key generates
CLASSIC_KEYS=(
  bluetooth cyngn-app media networkstack nfc platform
  releasekey sdk_sandbox shared testcert verity
)

# Full list of APEX modules that need their own keys
APEX_LIST=(
  com.android.adbd
  com.android.adservices
  com.android.adservices.api
  com.android.appsearch
  com.android.art
  com.android.bluetooth
  com.android.bt
  com.android.btservices
  com.android.cellbroadcast
  com.android.compos
  com.android.configinfrastructure
  com.android.connectivity.resources
  com.android.conscrypt
  com.android.crashrecovery
  com.android.devicelock
  com.android.extservices
  com.android.graphics.pdf
  com.android.hardware.authsecret
  com.android.hardware.biometrics.face.virtual
  com.android.hardware.biometrics.fingerprint.virtual
  com.android.hardware.boot
  com.android.hardware.cas
  com.android.hardware.contexthub
  com.android.hardware.drm.clearkey
  com.android.hardware.dumpstate
  com.android.hardware.gatekeeper.nonsecure
  com.android.hardware.neuralnetworks
  com.android.hardware.power
  com.android.hardware.rebootescrow
  com.android.hardware.thermal
  com.android.hardware.threadnetwork
  com.android.hardware.uwb
  com.android.hardware.vibrator
  com.android.hardware.wifi
  com.android.healthfitness
  com.android.hotspot2.osulogin
  com.android.i18n
  com.android.ipsec
  com.android.media
  com.android.media.swcodec
  com.android.mediaprovider
  com.android.nearby.halfsheet
  com.android.networkstack.tethering
  com.android.neuralnetworks
  com.android.nfcservices
  com.android.npumanager
  com.android.ondevicepersonalization
  com.android.os.statsd
  com.android.permission
  com.android.profiling
  com.android.resolv
  com.android.rkpd
  com.android.runtime
  com.android.safetycenter.resources
  com.android.scheduling
  com.android.sdkext
  com.android.support.apexer
  com.android.telephony
  com.android.telephonycore
  com.android.telephonymodules
  com.android.tethering
  com.android.tzdata
  com.android.uprobestats
  com.android.uwb
  com.android.uwb.resources
  com.android.virt
  com.android.vndk.current
  com.android.vndk.current.on_vendor
  com.android.webapp
  com.android.wifi
  com.android.wifi.dialog
  com.android.wifi.resources
  com.google.pixel.camera.hal
  com.google.pixel.vibrator.hal
  com.qorvo.uwb
)

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------

prompt_missing_data() {
  if [[ -z "${EMAIL}" ]]; then
    read -rp "Enter your e-mail address: " EMAIL
  fi

  if [[ -z "${NAME}" ]]; then
    read -rp "Enter your name (used in certificate CN): " NAME
  fi

  if [[ -z "${CODENAME}" ]]; then
    read -rp "Enter the device codename (e.g. rosemary): " CODENAME
  fi
}

choose_location_style() {
  echo
  echo "Choose the certificate location style:"
  echo
  echo "  1)  US / California / San Francisco"
  echo "  2)  US / California / Mountain View"
  echo "  3)  US / California / Los Angeles"
  echo "  4)  US / New York / New York"
  echo "  5)  US / Texas / Austin"
  echo "  6)  US / Washington / Seattle"
  echo "  7)  BR / Distrito Federal / Taguatinga   (original script)"
  echo "  8)  BR / São Paulo / São Paulo"
  echo "  9)  BR / Rio de Janeiro / Rio de Janeiro"
  echo " 10)  BR / Minas Gerais / Belo Horizonte"
  echo " 11)  BR / Paraná / Curitiba"
  echo " 12)  BR / Rio Grande do Sul / Porto Alegre"
  echo " 13)  DE / Berlin / Berlin"
  echo " 14)  GB / England / London"
  echo " 15)  JP / Tokyo / Tokyo"
  echo " 16)  IN / Karnataka / Bangalore"
  echo
  read -rp "Enter number (1-16): " choice

  case "${choice}" in
    1)
      SUBJECT="/C=US/ST=California/L=San Francisco/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    2)
      SUBJECT="/C=US/ST=California/L=Mountain View/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    3)
      SUBJECT="/C=US/ST=California/L=Los Angeles/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    4)
      SUBJECT="/C=US/ST=New York/L=New York/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    5)
      SUBJECT="/C=US/ST=Texas/L=Austin/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    6)
      SUBJECT="/C=US/ST=Washington/L=Seattle/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    7)
      SUBJECT="/C=BR/ST=Distrito Federal/L=Taguatinga/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    8)
      SUBJECT="/C=BR/ST=São Paulo/L=São Paulo/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    9)
      SUBJECT="/C=BR/ST=Rio de Janeiro/L=Rio de Janeiro/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    10)
      SUBJECT="/C=BR/ST=Minas Gerais/L=Belo Horizonte/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    11)
      SUBJECT="/C=BR/ST=Paraná/L=Curitiba/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    12)
      SUBJECT="/C=BR/ST=Rio Grande do Sul/L=Porto Alegre/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    13)
      SUBJECT="/C=DE/ST=Berlin/L=Berlin/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    14)
      SUBJECT="/C=GB/ST=England/L=London/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    15)
      SUBJECT="/C=JP/ST=Tokyo/L=Tokyo/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    16)
      SUBJECT="/C=IN/ST=Karnataka/L=Bangalore/O=Android/OU=Android/CN=\( {NAME}/emailAddress= \){EMAIL}"
      ;;
    *)
      echo "Invalid choice. Please enter a number between 1 and 16."
      exit 1
      ;;
  esac

  echo "→ Using subject: ${SUBJECT}"
}

generate_classic_keys() {
  echo "→ Generating classic platform keys in ${CERTS_DIR} …"
  mkdir -p "${CERTS_DIR}"

  for cert in "${CLASSIC_KEYS[@]}"; do
    ./development/tools/make_key "\( {CERTS_DIR}/ \){cert}" "${SUBJECT}"
  done

  # testkey is just an alias of releasekey
  ln -sf releasekey.pk8          "${CERTS_DIR}/testkey.pk8"
  ln -sf releasekey.x509.pem     "${CERTS_DIR}/testkey.x509.pem"

  # Make a local copy of make_key and force 4096-bit keys
  cp ./development/tools/make_key "${CERTS_DIR}/"
  sed -i 's|2048|4096|g' "${CERTS_DIR}/make_key"
}

choose_password_mode() {
  echo
  echo "Do you want the APEX keys to be protected by a password?"
  read -rp "(with / without): " NUMSABU

  case "${NUMSABU}" in
    [Ww][Ii][Tt][Hh]|[Ww])
      USE_PASSWORD=true
      echo
      echo 'When "Please enter your password" appears, type your password 2 or more times.'
      sleep 3
      ;;
    [Ww][Ii][Tt][Hh][Oo][Uu][Tt]|[Ww][Oo])
      USE_PASSWORD=false
      echo
      echo 'When "Please enter your password" appears, just press Enter 2 or more times.'
      sleep 3
      ;;
    *)
      echo "Do you want a password or not??"
      exit 1
      ;;
  esac
}

generate_apex_keys() {
  echo "→ Generating APEX keys …"

  for apex in "${APEX_LIST[@]}"; do
    local apex_subject="/C=US/ST=California/L=San Francisco/O=Android/OU=Android/CN=\( {apex}/emailAddress= \){EMAIL}"

    "\( {CERTS_DIR}/make_key" " \){CERTS_DIR}/\( {apex}" " \){apex_subject}"

    if [[ "${USE_PASSWORD}" == true ]]; then
      openssl pkcs8 -in  "\( {CERTS_DIR}/ \){apex}.pk8" \
                    -inform DER \
                    -out "\( {CERTS_DIR}/ \){apex}.pem"
    else
      openssl pkcs8 -in  "\( {CERTS_DIR}/ \){apex}.pk8" \
                    -inform DER \
                    -nocrypt \
                    -out "\( {CERTS_DIR}/ \){apex}.pem"
    fi
  done
}

# ---------------------------------------------------------------------------
# The actual signing procedure (target-files → signed OTA)
# ---------------------------------------------------------------------------
sign_build() {
  echo "→ Running breakfast ${CODENAME}"
  breakfast "${CODENAME}"

  echo "→ Building target-files-package + otatools"
  mka target-files-package otatools

  croot

  echo "→ Signing target-files …"
  # shellcheck disable=SC2086,SC2046
  sign_target_files_apks -o -d "${CERTS_DIR}" \
    --extra_apks com.android.appsearch.apk.apk=${CERTS_DIR}/releasekey \
    --extra_apks AdServicesApk.apk=${CERTS_DIR}/releasekey \
    --extra_apks FederatedCompute.apk=${CERTS_DIR}/releasekey \
    --extra_apks HalfSheetUX.apk=${CERTS_DIR}/releasekey \
    --extra_apks HealthConnectBackupRestore.apk=${CERTS_DIR}/releasekey \
    --extra_apks HealthConnectController.apk=${CERTS_DIR}/releasekey \
    --extra_apks OsuLogin.apk=${CERTS_DIR}/releasekey \
    --extra_apks SafetyCenterResources.apk=${CERTS_DIR}/releasekey \
    --extra_apks ServiceConnectivityResources.apk=${CERTS_DIR}/releasekey \
    --extra_apks ServiceUwbResources.apk=${CERTS_DIR}/releasekey \
    --extra_apks ServiceWifiResources.apk=${CERTS_DIR}/releasekey \
    --extra_apks TelecomServiceResources.apk=${CERTS_DIR}/releasekey \
    --extra_apks TelecomUi.apk=${CERTS_DIR}/releasekey \
    --extra_apks WebAppService.apk=${CERTS_DIR}/releasekey \
    --extra_apks WifiDialog.apk=${CERTS_DIR}/releasekey \
    --extra_apks com.android.adbd.apex=${CERTS_DIR}/com.android.adbd \
    --extra_apks com.android.adservices.apex=${CERTS_DIR}/com.android.adservices \
    --extra_apks com.android.adservices.api.apex=${CERTS_DIR}/com.android.adservices.api \
    --extra_apks com.android.appsearch.apex=${CERTS_DIR}/com.android.appsearch \
    --extra_apks com.android.art.apex=${CERTS_DIR}/com.android.art \
    --extra_apks com.android.bluetooth.apex=${CERTS_DIR}/com.android.bluetooth \
    --extra_apks com.android.bt.apex=${CERTS_DIR}/com.android.bt \
    --extra_apks com.android.btservices.apex=${CERTS_DIR}/com.android.btservices \
    --extra_apks com.android.cellbroadcast.apex=${CERTS_DIR}/com.android.cellbroadcast \
    --extra_apks com.android.compos.apex=${CERTS_DIR}/com.android.compos \
    --extra_apks com.android.configinfrastructure.apex=${CERTS_DIR}/com.android.configinfrastructure \
    --extra_apks com.android.connectivity.resources.apex=${CERTS_DIR}/com.android.connectivity.resources \
    --extra_apks com.android.conscrypt.apex=${CERTS_DIR}/com.android.conscrypt \
    --extra_apks com.android.crashrecovery.apex=${CERTS_DIR}/com.android.crashrecovery \
    --extra_apks com.android.devicelock.apex=${CERTS_DIR}/com.android.devicelock \
    --extra_apks com.android.extservices.apex=${CERTS_DIR}/com.android.extservices \
    --extra_apks com.android.graphics.pdf.apex=${CERTS_DIR}/com.android.graphics.pdf \
    --extra_apks com.android.hardware.authsecret.apex=${CERTS_DIR}/com.android.hardware.authsecret \
    --extra_apks com.android.hardware.biometrics.face.virtual.apex=${CERTS_DIR}/com.android.hardware.biometrics.face.virtual \
    --extra_apks com.android.hardware.biometrics.fingerprint.virtual.apex=${CERTS_DIR}/com.android.hardware.biometrics.fingerprint.virtual \
    --extra_apks com.android.hardware.boot.apex=${CERTS_DIR}/com.android.hardware.boot \
    --extra_apks com.android.hardware.cas.apex=${CERTS_DIR}/com.android.hardware.cas \
    --extra_apks com.android.hardware.contexthub.apex=${CERTS_DIR}/com.android.hardware.contexthub \
    --extra_apks com.android.hardware.drm.clearkey.apex=${CERTS_DIR}/com.android.hardware.drm.clearkey \
    --extra_apks com.android.hardware.dumpstate.apex=${CERTS_DIR}/com.android.hardware.dumpstate \
    --extra_apks com.android.hardware.gatekeeper.nonsecure.apex=${CERTS_DIR}/com.android.hardware.gatekeeper.nonsecure \
    --extra_apks com.android.hardware.neuralnetworks.apex=${CERTS_DIR}/com.android.hardware.neuralnetworks \
    --extra_apks com.android.hardware.power.apex=${CERTS_DIR}/com.android.hardware.power \
    --extra_apks com.android.hardware.rebootescrow.apex=${CERTS_DIR}/com.android.hardware.rebootescrow \
    --extra_apks com.android.hardware.thermal.apex=${CERTS_DIR}/com.android.hardware.thermal \
    --extra_apks com.android.hardware.threadnetwork.apex=${CERTS_DIR}/com.android.hardware.threadnetwork \
    --extra_apks com.android.hardware.uwb.apex=${CERTS_DIR}/com.android.hardware.uwb \
    --extra_apks com.android.hardware.vibrator.apex=${CERTS_DIR}/com.android.hardware.vibrator \
    --extra_apks com.android.hardware.wifi.apex=${CERTS_DIR}/com.android.hardware.wifi \
    --extra_apks com.android.healthfitness.apex=${CERTS_DIR}/com.android.healthfitness \
    --extra_apks com.android.hotspot2.osulogin.apex=${CERTS_DIR}/com.android.hotspot2.osulogin \
    --extra_apks com.android.i18n.apex=${CERTS_DIR}/com.android.i18n \
    --extra_apks com.android.ipsec.apex=${CERTS_DIR}/com.android.ipsec \
    --extra_apks com.android.media.apex=${CERTS_DIR}/com.android.media \
    --extra_apks com.android.media.swcodec.apex=${CERTS_DIR}/com.android.media.swcodec \
    --extra_apks com.android.mediaprovider.apex=${CERTS_DIR}/com.android.mediaprovider \
    --extra_apks com.android.nearby.halfsheet.apex=${CERTS_DIR}/com.android.nearby.halfsheet \
    --extra_apks com.android.networkstack.tethering.apex=${CERTS_DIR}/com.android.networkstack.tethering \
    --extra_apks com.android.neuralnetworks.apex=${CERTS_DIR}/com.android.neuralnetworks \
    --extra_apks com.android.nfcservices.apex=${CERTS_DIR}/com.android.nfcservices \
    --extra_apks com.android.npumanager.apex=${CERTS_DIR}/com.android.npumanager \
    --extra_apks com.android.ondevicepersonalization.apex=${CERTS_DIR}/com.android.ondevicepersonalization \
    --extra_apks com.android.os.statsd.apex=${CERTS_DIR}/com.android.os.statsd \
    --extra_apks com.android.permission.apex=${CERTS_DIR}/com.android.permission \
    --extra_apks com.android.profiling.apex=${CERTS_DIR}/com.android.profiling \
    --extra_apks com.android.resolv.apex=${CERTS_DIR}/com.android.resolv \
    --extra_apks com.android.rkpd.apex=${CERTS_DIR}/com.android.rkpd \
    --extra_apks com.android.runtime.apex=${CERTS_DIR}/com.android.runtime \
    --extra_apks com.android.safetycenter.resources.apex=${CERTS_DIR}/com.android.safetycenter.resources \
    --extra_apks com.android.scheduling.apex=${CERTS_DIR}/com.android.scheduling \
    --extra_apks com.android.sdkext.apex=${CERTS_DIR}/com.android.sdkext \
    --extra_apks com.android.support.apexer.apex=${CERTS_DIR}/com.android.support.apexer \
    --extra_apks com.android.telephony.apex=${CERTS_DIR}/com.android.telephony \
    --extra_apks com.android.telephonycore.apex=${CERTS_DIR}/com.android.telephonycore \
    --extra_apks com.android.telephonymodules.apex=${CERTS_DIR}/com.android.telephonymodules \
    --extra_apks com.android.tethering.apex=${CERTS_DIR}/com.android.tethering \
    --extra_apks com.android.tzdata.apex=${CERTS_DIR}/com.android.tzdata \
    --extra_apks com.android.uprobestats.apex=${CERTS_DIR}/com.android.uprobestats \
    --extra_apks com.android.uwb.apex=${CERTS_DIR}/com.android.uwb \
    --extra_apks com.android.uwb.resources.apex=${CERTS_DIR}/com.android.uwb.resources \
    --extra_apks com.android.virt.apex=${CERTS_DIR}/com.android.virt \
    --extra_apks com.android.vndk.current.apex=${CERTS_DIR}/com.android.vndk.current \
    --extra_apks com.android.vndk.current.on_vendor.apex=${CERTS_DIR}/com.android.vndk.current.on_vendor \
    --extra_apks com.android.webapp.apex=${CERTS_DIR}/com.android.webapp \
    --extra_apks com.android.wifi.apex=${CERTS_DIR}/com.android.wifi \
    --extra_apks com.android.wifi.dialog.apex=${CERTS_DIR}/com.android.wifi.dialog \
    --extra_apks com.android.wifi.resources.apex=${CERTS_DIR}/com.android.wifi.resources \
    --extra_apks com.google.pixel.camera.hal.apex=${CERTS_DIR}/com.google.pixel.camera.hal \
    --extra_apks com.google.pixel.vibrator.hal.apex=${CERTS_DIR}/com.google.pixel.vibrator.hal \
    --extra_apks com.qorvo.uwb.apex=${CERTS_DIR}/com.qorvo.uwb \
    --extra_apex_payload_key com.android.adbd.apex=${CERTS_DIR}/com.android.adbd.pem \
    --extra_apex_payload_key com.android.adservices.apex=${CERTS_DIR}/com.android.adservices.pem \
    --extra_apex_payload_key com.android.adservices.api.apex=${CERTS_DIR}/com.android.adservices.api.pem \
    --extra_apex_payload_key com.android.appsearch.apex=${CERTS_DIR}/com.android.appsearch.pem \
    --extra_apex_payload_key com.android.art.apex=${CERTS_DIR}/com.android.art.pem \
    --extra_apex_payload_key com.android.bluetooth.apex=${CERTS_DIR}/com.android.bluetooth.pem \
    --extra_apex_payload_key com.android.bt.apex=${CERTS_DIR}/com.android.bt.pem \
    --extra_apex_payload_key com.android.btservices.apex=${CERTS_DIR}/com.android.btservices.pem \
    --extra_apex_payload_key com.android.cellbroadcast.apex=${CERTS_DIR}/com.android.cellbroadcast.pem \
    --extra_apex_payload_key com.android.compos.apex=${CERTS_DIR}/com.android.compos.pem \
    --extra_apex_payload_key com.android.configinfrastructure.apex=${CERTS_DIR}/com.android.configinfrastructure.pem \
    --extra_apex_payload_key com.android.connectivity.resources.apex=${CERTS_DIR}/com.android.connectivity.resources.pem \
    --extra_apex_payload_key com.android.conscrypt.apex=${CERTS_DIR}/com.android.conscrypt.pem \
    --extra_apex_payload_key com.android.crashrecovery.apex=${CERTS_DIR}/com.android.crashrecovery.pem \
    --extra_apex_payload_key com.android.devicelock.apex=${CERTS_DIR}/com.android.devicelock.pem \
    --extra_apex_payload_key com.android.extservices.apex=${CERTS_DIR}/com.android.extservices.pem \
    --extra_apex_payload_key com.android.graphics.pdf.apex=${CERTS_DIR}/com.android.graphics.pdf.pem \
    --extra_apex_payload_key com.android.hardware.authsecret.apex=${CERTS_DIR}/com.android.hardware.authsecret.pem \
    --extra_apex_payload_key com.android.hardware.biometrics.face.virtual.apex=${CERTS_DIR}/com.android.hardware.biometrics.face.virtual.pem \
    --extra_apex_payload_key com.android.hardware.biometrics.fingerprint.virtual.apex=${CERTS_DIR}/com.android.hardware.biometrics.fingerprint.virtual.pem \
    --extra_apex_payload_key com.android.hardware.boot.apex=${CERTS_DIR}/com.android.hardware.boot.pem \
    --extra_apex_payload_key com.android.hardware.cas.apex=${CERTS_DIR}/com.android.hardware.cas.pem \
    --extra_apex_payload_key com.android.hardware.contexthub.apex=${CERTS_DIR}/com.android.hardware.contexthub.pem \
    --extra_apex_payload_key com.android.hardware.drm.clearkey.apex=${CERTS_DIR}/com.android.hardware.drm.clearkey.pem \
    --extra_apex_payload_key com.android.hardware.dumpstate.apex=${CERTS_DIR}/com.android.hardware.dumpstate.pem \
    --extra_apex_payload_key com.android.hardware.gatekeeper.nonsecure.apex=${CERTS_DIR}/com.android.hardware.gatekeeper.nonsecure.pem \
    --extra_apex_payload_key com.android.hardware.neuralnetworks.apex=${CERTS_DIR}/com.android.hardware.neuralnetworks.pem \
    --extra_apex_payload_key com.android.hardware.power.apex=${CERTS_DIR}/com.android.hardware.power.pem \
    --extra_apex_payload_key com.android.hardware.rebootescrow.apex=${CERTS_DIR}/com.android.hardware.rebootescrow.pem \
    --extra_apex_payload_key com.android.hardware.thermal.apex=${CERTS_DIR}/com.android.hardware.thermal.pem \
    --extra_apex_payload_key com.android.hardware.threadnetwork.apex=${CERTS_DIR}/com.android.hardware.threadnetwork.pem \
    --extra_apex_payload_key com.android.hardware.uwb.apex=${CERTS_DIR}/com.android.hardware.uwb.pem \
    --extra_apex_payload_key com.android.hardware.vibrator.apex=${CERTS_DIR}/com.android.hardware.vibrator.pem \
    --extra_apex_payload_key com.android.hardware.wifi.apex=${CERTS_DIR}/com.android.hardware.wifi.pem \
    --extra_apex_payload_key com.android.healthfitness.apex=${CERTS_DIR}/com.android.healthfitness.pem \
    --extra_apex_payload_key com.android.hotspot2.osulogin.apex=${CERTS_DIR}/com.android.hotspot2.osulogin.pem \
    --extra_apex_payload_key com.android.i18n.apex=${CERTS_DIR}/com.android.i18n.pem \
    --extra_apex_payload_key com.android.ipsec.apex=${CERTS_DIR}/com.android.ipsec.pem \
    --extra_apex_payload_key com.android.media.apex=${CERTS_DIR}/com.android.media.pem \
    --extra_apex_payload_key com.android.media.swcodec.apex=${CERTS_DIR}/com.android.media.swcodec.pem \
    --extra_apex_payload_key com.android.mediaprovider.apex=${CERTS_DIR}/com.android.mediaprovider.pem \
    --extra_apex_payload_key com.android.nearby.halfsheet.apex=${CERTS_DIR}/com.android.nearby.halfsheet.pem \
    --extra_apex_payload_key com.android.networkstack.tethering.apex=${CERTS_DIR}/com.android.networkstack.tethering.pem \
    --extra_apex_payload_key com.android.neuralnetworks.apex=${CERTS_DIR}/com.android.neuralnetworks.pem \
    --extra_apex_payload_key com.android.nfcservices.apex=${CERTS_DIR}/com.android.nfcservices.pem \
    --extra_apex_payload_key com.android.npumanager.apex=${CERTS_DIR}/com.android.npumanager.pem \
    --extra_apex_payload_key com.android.ondevicepersonalization.apex=${CERTS_DIR}/com.android.ondevicepersonalization.pem \
    --extra_apex_payload_key com.android.os.statsd.apex=${CERTS_DIR}/com.android.os.statsd.pem \
    --extra_apex_payload_key com.android.permission.apex=${CERTS_DIR}/com.android.permission.pem \
    --extra_apex_payload_key com.android.profiling.apex=${CERTS_DIR}/com.android.profiling.pem \
    --extra_apex_payload_key com.android.resolv.apex=${CERTS_DIR}/com.android.resolv.pem \
    --extra_apex_payload_key com.android.rkpd.apex=${CERTS_DIR}/com.android.rkpd.pem \
    --extra_apex_payload_key com.android.runtime.apex=${CERTS_DIR}/com.android.runtime.pem \
    --extra_apex_payload_key com.android.safetycenter.resources.apex=${CERTS_DIR}/com.android.safetycenter.resources.pem \
    --extra_apex_payload_key com.android.scheduling.apex=${CERTS_DIR}/com.android.scheduling.pem \
    --extra_apex_payload_key com.android.sdkext.apex=${CERTS_DIR}/com.android.sdkext.pem \
    --extra_apex_payload_key com.android.support.apexer.apex=${CERTS_DIR}/com.android.support.apexer.pem \
    --extra_apex_payload_key com.android.telephony.apex=${CERTS_DIR}/com.android.telephony.pem \
    --extra_apex_payload_key com.android.telephonycore.apex=${CERTS_DIR}/com.android.telephonycore.pem \
    --extra_apex_payload_key com.android.telephonymodules.apex=${CERTS_DIR}/com.android.telephonymodules.pem \
    --extra_apex_payload_key com.android.tethering.apex=${CERTS_DIR}/com.android.tethering.pem \
    --extra_apex_payload_key com.android.tzdata.apex=${CERTS_DIR}/com.android.tzdata.pem \
    --extra_apex_payload_key com.android.uprobestats.apex=${CERTS_DIR}/com.android.uprobestats.pem \
    --extra_apex_payload_key com.android.uwb.apex=${CERTS_DIR}/com.android.uwb.pem \
    --extra_apex_payload_key com.android.uwb.resources.apex=${CERTS_DIR}/com.android.uwb.resources.pem \
    --extra_apex_payload_key com.android.virt.apex=${CERTS_DIR}/com.android.virt.pem \
    --extra_apex_payload_key com.android.vndk.current.apex=${CERTS_DIR}/com.android.vndk.current.pem \
    --extra_apex_payload_key com.android.vndk.current.on_vendor.apex=${CERTS_DIR}/com.android.vndk.current.on_vendor.pem \
    --extra_apex_payload_key com.android.webapp.apex=${CERTS_DIR}/com.android.webapp.pem \
    --extra_apex_payload_key com.android.wifi.apex=${CERTS_DIR}/com.android.wifi.pem \
    --extra_apex_payload_key com.android.wifi.dialog.apex=${CERTS_DIR}/com.android.wifi.dialog.pem \
    --extra_apex_payload_key com.android.wifi.resources.apex=${CERTS_DIR}/com.android.wifi.resources.pem \
    --extra_apex_payload_key com.google.pixel.camera.hal.apex=${CERTS_DIR}/com.google.pixel.camera.hal.pem \
    --extra_apex_payload_key com.google.pixel.vibrator.hal.apex=${CERTS_DIR}/com.google.pixel.vibrator.hal.pem \
    --extra_apex_payload_key com.qorvo.uwb.apex=${CERTS_DIR}/com.qorvo.uwb.pem \
    ${OUT}/obj/PACKAGING/target_files_intermediates/*-target_files*.zip \
    signed-target_files.zip

  echo "→ Generating signed OTA package …"
  ota_from_target_files -k "${CERTS_DIR}/releasekey" \
    --block \
    --backup=true \
    signed-target_files.zip \
    signed-ota_update.zip

  echo
  echo "Done! Signed files created:"
  echo "  • signed-target_files.zip"
  echo "  • signed-ota_update.zip"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  prompt_missing_data
  choose_location_style
  generate_classic_keys
  choose_password_mode
  generate_apex_keys
  sign_build
}

main "$@"
