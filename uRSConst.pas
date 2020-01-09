unit uRSConst;

interface

uses
  WinApi.Messages;

const
  LOG_FILE_NAME = 'log.txt';
  API_FILE_NAME = 'api.txt';
  SETTINGS_FILE_NAME = 'settings.ini';
  // rp modules
  RP_Users = 'Users';
  RP_Tests = 'Tests';
  RP_Files = 'Files';
  RP_System = 'System';
  // protocol settings
  DEFAULT_HTTP_PROTOCOL = 'http';
  DEFAULT_HTTP_HOST = 'localhost';
  DEFAULT_HTTP_PORT = 7777;
  // GUI Request types
  GUI_REQUEST_TYPE_GET = 0;
  GUI_REQUEST_TYPE_POST = 1;
  GUI_REQUEST_TYPE_POST_APPLICATION_JSON = 0;
  GUI_REQUEST_TYPE_POST_URL_ENCODED = 1;
  GUI_REQUEST_TYPE_POST_MULTIPART = 2;
  // messages
  WM_WORK_TIME = WM_USER + 1000;
  WM_APP_MEMORY = WM_USER + 1001;
  WM_SERVER_START = WM_USER + 1002;
  WM_SERVER_STOP = WM_USER + 1003;
  // directories
  SERVERS_RELATIVE_DIR = 'servers';

implementation

end.

