<?php exit; // DO NOT DELETE?>
; <?php exit; // DO NOT DELETE ?>
; DO NOT DELETE THE ABOVE LINE!!!
; Doing so will expose this configuration file through your web site!
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
; config.inc.php
;
; Docker configuration for OJS
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;
; General Settings ;
;;;;;;;;;;;;;;;;;;;;

[general]

; Set this to On once the system has been installed
installed = On

; The canonical URL to the OJS installation (excluding the trailing slash)
base_url = "${APP_URL}"

; Enable strict mode
strict = Off

; Session cookie name
session_cookie_name = OJSSID

; Number of days to save login cookie for if user selects to remember
session_lifetime = 30

; SameSite configuration for the cookie
session_cookie_samesite = Lax

; Short name for this site
short_name = "ojs"

; Database Configuration
[database]

driver = mysql
host = "${DB_HOST}"
port = "${DB_PORT}"
username = "${DB_USER}"
password = "${DB_PASSWORD}"
name = "${DB_DATABASE}"

; Generate database persistent connections
persistent = Off

; Database collation
collation = utf8_general_ci

;;;;;;;;;;;;;;;;
; File Settings ;
;;;;;;;;;;;;;;;;

[files]

; Complete path to directory to store uploaded files
files_dir = storage
public_dir = public

; Path to the directory to store file uploads during the review process
review_dir = storage/review

; Path to the directory to store temporary files
temp_dir = storage/tmp

;;;;;;;;;;;;;;;;
; Email Settings ;
;;;;;;;;;;;;;;;;

[email]

; Default method to send emails
; Available options: sendmail, smtp, log
default = "${SMTP_METHOD}"

; Allow envelope sender to be specified
; (may not be possible with some server configurations)
allow_envelope_sender = Off

; Default envelope sender to use if none is specified elsewhere
default_envelope_sender = "${SMTP_FROM_EMAIL:-noreply@example.com}"

; Force the default envelope sender (don't allow other senders)
force_default_envelope_sender = Off

; Force a DMARC compliant from header (RFC5321.MailFrom != RFC5322.From)
force_dmarc_compliant_from = Off

; SMTP Configuration (if using smtp)
smtp_server = "${SMTP_HOST}"
smtp_port = "${SMTP_PORT}"
smtp_auth = "${SMTP_AUTH}"
smtp_username = "${SMTP_USERNAME}"
smtp_password = "${SMTP_PASSWORD}"

; Enable SMTP authentication
; Supported mechanisms: ssl, tls
smtp_suppress_errors = Off

; SMTP timeout in seconds
smtp_timeout = 5

; Enable SMTP over SSL/TLS
; Use 'ssl' for SMTP over SSL, 'tls' for STARTTLS
smtp_encryption = "${SMTP_ENCRYPTION}"

; Additional SMTP settings for production
smtp_auth_mechanism = "${SMTP_AUTH_MECHANISM:-PLAIN}"

;;;;;;;;;;;;;;;;;;
; Security Settings ;
;;;;;;;;;;;;;;;;;;

[security]

; Force SSL connections site-wide
force_ssl = Off

; Force login over SSL
force_login_ssl = Off

; This check will invalidate a session if the user's IP address changes
session_check_ip = Off

; Allow "Remember me" feature for login
remember_me = On

; Encryption (encryption key will be generated automatically on install)
encryption = sha1

; Allowed HTML tags for fields that permit restricted HTML
allowed_html = "a[href|target|title],em,strong,cite,code,ul,ol,li[class],dl,dt,dd,b,i,u,img[src|alt],sup,sub,br,p"

; Cache settings
[cache]

; Choose the type of cache to use. Options are:
; - none: no caching
; - file: file-based caching
; - memcache: Use memcache (requires memcache php extension)
cache = file

; Settings for memcache (if selected above)
memcache_hostname = localhost
memcache_port = 11211

;;;;;;;;;;;;;;;;;;;;
; Locale Settings ;
;;;;;;;;;;;;;;;;;;;;

[i18n]

; Default locale
locale = en_US

; Client output/input character set
client_charset = utf-8

; Database character set (must be set to "utf8" for non-English locales)
connection_charset = utf8

; Database storage character set (must be set to "utf8" for non-English locales)
database_charset = utf8

;;;;;;;;;;;;;;;;;;;;
; Plugin Settings ;
;;;;;;;;;;;;;;;;;;;;

[oai]

; Enable OAI-PMH interface
oai = On

;;;;;;;;;;;;;;;;
; Debug Settings ;
;;;;;;;;;;;;;;;;

[debug]

; Display execution stats in the footer
show_stats = Off

; Display current stack trace on error
show_stacktrace = Off

; Log web service requests to the error log
log_web_service_info = Off

; Enable the profiler to see database queries and page generation time
profiler = Off