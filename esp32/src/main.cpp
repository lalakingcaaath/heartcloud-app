#include <Arduino.h>
#include <WiFi.h>
#include <FirebaseClient.h>
#include <WiFiClientSecure.h>
#include "ExampleFunctions.h" // Provides the functions used in the examples.


// Functions
void processData(AsyncResult &aResult);


// WIFI Settings
#define SSID "WWHSUPERTUNA"
#define PASSWORD "AhvaLevi12251018."

// FIREBASE API
#define FIREBASE_PROJECT_ID "heartcloud-c5817"
#define FIREBASE_CLIENT_EMAIL "firebase-adminsdk-fbsvc@heartcloud-c5817.iam.gserviceaccount.com"
const char PRIVATE_KEY[] PROGMEM = "-----BEGIN PRIVATE KEY-----\nMIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDV+AE8l4/JLyIW\n36T5Sy9g6EMzkw98OTSUgqIPBOrtMFCvv/j4brZG7rFVxi+TMFy8N3rJfCt4/xbH\nfvueLV2YXNUvUVpEryXRIZBIwc5iQI76DshdzOlQVAgTcBVFBHDE14jMShktrLV3\nMx/LtvH8wDiuLFkPmMUEWpcvJikwuXGYJw5la1LcEhc+JF3kbfCvOJu0MpSmLudF\n4Pn2Ai1Wpf0oZvAAU4Q3FNJnmvCtbNToP88AS216j/zmnQV3PHgwEM3kF3Ccktb/\ndgLUGwLd7FT1oslVGTZ8LZjcrbCfcGaCSvXDYAR7txuDgWFBvaMYNWb677FtGNSh\nU6HVDMsjAgMBAAECggEASCCN6ir9IUhuKV/CcPbTRcuFu8D7G1j9TIKstntl5ga/\nbD8+YiCP+WFFDjD8oJVQ7XGWRo1A6kyzFRTNJQkN3+qLQqQd1cFk8hZqWNxcAerZ\nR5nsGRKWI6nv/v1tbhKNIQ2244am7iqmEUR+l2FYOWdis/PnIcbRwyH2jMJEaFO8\n1UmiKPISkbmmGo6wRnYin+4X4KlzlNWcvNUWgs/xrENHFAKk0Gom1eS2NRpSHJaV\n9CAnM4HOz0jo0Mv/LhIy3FkC7razgmvcharyh/4OFQDTA3et7+eeO6P3IPMvAX3p\nO+hb417zMcw/3f53sef39NWdiExZtwyVjD2ecdXJoQKBgQD3+CaHpCky7Rr5Plum\nq5HOIEWN/Be3P56NRqkOXr2QxgvU6ijCaPOaPUJSoDmPOHb0MBCf41DxkYla81OU\nUtFIJ9x2WY4gcbLGD87aKBQ1Uom23BTZ8KRF9YxVvgdbBvIL1iRRuPQNr00BK+v6\n8H2QWXHtM4HVgsA8FLwYH603tQKBgQDc5fbkQzm9n79zbDzXDWaHQaxG4pgOyPRc\nMYj/MuNoF6jnl0OvM4uV/Hg0e5bhKxFhl4dCidjCcdvxDYMyQ/fan3OHDgRZ14rW\neBJqCkCsCwzd7DD73aX0bZMXxTXupBIjTrvlNtcNjGjJJ4lIRvbQ6qPt3h6e7HOc\nqjhkrgwOdwKBgAxYl5qDSuXVNlWYjDmlKzJHGw9xsMCX8033aa1kfC28HpSwP+1G\nCnLwf9/bSGJgHlQUHI/JYptUcrFLkiq9YNwl1+0wkkn9PzhrSxJDkpYBEQhAtu0O\n9S7iheUy++zFUMHUHKTQ/526z6uyQyKQXMAWI/z6Zol55BZZte/Bi/9NAoGAOs6B\nzrzS11d62Vh8TegEXoeuPGTAhFcdLpoFVaMPhTufPKA5ZZ/8Th6bRaWNQj577xYu\n7RjTethi7CZjwfL0PeBrGg4yPFS0YmouxMob83ExqLbjR3n3Xz34hcB7nh9RsNKa\nFOhnkfTKRJrg4jv6Ix4ELCQQ1NAv6wop3yuyi/sCgYAQPI5rUgcV3OBo9wKnvMQM\nO1mDfwdZ4YKzGyt+nnmxixNtOe+23RMZOFO8yrf6Bg0nJYJNU2YRr44tW/TJnnRl\nEaJOgRv0ZVCnZP1s4r5L7A6bFqR4yOfJpCu4CIjkOhMTXZzhiX+cAGVqbFv+PbEj\nRGx8JG0ZFz7h4qoPMl/3oA==\n-----END PRIVATE KEY-----\n";
ServiceAuth sa_auth(FIREBASE_CLIENT_EMAIL, FIREBASE_PROJECT_ID, PRIVATE_KEY, 3000/* expire period in seconds (<= 3600) */);
FirebaseApp app;

WiFiClientSecure ssl_client;

CloudStorage cstorage;
// This uses built-in core WiFi/Ethernet for network connection.
// See examples/App/NetworkInterfaces for more network examples.
using AsyncClient = AsyncClientClass;
AsyncClient aClient(ssl_client);
AsyncResult cloudStorageResult;
WiFiServer server(80);

#define STORAGE_BUCKET_ID "heartcloud-c5817.firebasestorage.app"

String header;

// EXAMPLE FILE
FileConfig media_file("/sample.txt", file_operation_callback);

// for record state
boolean isRecordOn = false;

bool taskComplete = false;

// PINOUTS



void setup(){
  Serial.begin(115200);

  // Start the file system 
  if(!SPIFFS.begin(true)){
    Serial.println("An Error has occurred while mounting SPIFFS");
    return;
  }

  // Checks the SSID and PASSWORD 
  if (String(SSID) == "" || String(PASSWORD) == "") {
    Serial.println("NO SSID OR PASSWORD INFO");
    return;
  }

  // Connect to wifi
  WiFi.begin(SSID, PASSWORD);
  while (WiFi.status() != WL_CONNECTED)
  {
    Serial.print(".");
    delay(300);
  }
  Serial.println();
  Serial.print("Connected with IP: ");
  Serial.println(WiFi.localIP());  

  Firebase.printf("Firebase Client v%s\n", FIREBASE_CLIENT_VERSION);

  File file = SPIFFS.open("/sample.txt", "r");
  if (!file || file.isDirectory()) {
    Serial.println("❌ File does not exist or is a directory!");
  } else {
    Serial.println("✅ File exists and ready to upload.");
    file.close();
  }

  ssl_client.setInsecure();

  app.setTime(get_ntp_time());


  Serial.println("Initializing app...");
  initializeApp(aClient, app, getAuth(sa_auth), auth_debug_print, "🔐 authTask");


  app.getApp<CloudStorage>(cstorage);

}

void loop() {
  app.loop();

  if(app.ready() && !taskComplete) {
    taskComplete = true;
    GoogleCloudStorage::UploadOptions options;
    // for any other file types. refer to the https://developer.mozilla.org/en-US/docs/Web/HTTP/Guides/MIME_types/Common_types
    // in this example. we have txt file extention;
    options.mime = "text/plain";
    // options.uploadType = GoogleCloudStorage::upload_type_resumable; // or 
    options.uploadType = GoogleCloudStorage::upload_type_simple;
    

    Serial.println("Uploading file...");

    // this function will return boolean if the upload is sucess
    bool isUploaded = cstorage.upload(aClient, GoogleCloudStorage::Parent(STORAGE_BUCKET_ID, "sample.txt"), getFile(media_file), options);

    if (isUploaded)
        Serial.println("🔼 Upload task(await), complete!✅️");
    else
        Firebase.printf("Error, msg: %s, code: %d\n", aClient.lastError().message().c_str(), aClient.lastError().code());
  }

  processData(cloudStorageResult); // Uncomment this code.
}


// For Debug Purposes
void processData(AsyncResult &aResult)
{
    // Exits when no result available when call from the loop.
    if (!aResult.isResult())
        return;

    if (aResult.isEvent())
    {
        Firebase.printf("Event task: %s, msg: %s, code: %d\n", aResult.uid().c_str(), aResult.eventLog().message().c_str(), aResult.eventLog().code());
    }

    if (aResult.isDebug())
    {
        Firebase.printf("Debug task: %s, msg: %s\n", aResult.uid().c_str(), aResult.debug().c_str());
    }

    if (aResult.isError())
    {
        Firebase.printf("Error task: %s, msg: %s, code: %d\n", aResult.uid().c_str(), aResult.error().message().c_str(), aResult.error().code());
    }

    if (aResult.downloadProgress())
    {
        Firebase.printf("Downloaded, task: %s, %d%s (%d of %d)\n", aResult.uid().c_str(), aResult.downloadInfo().progress, "%", aResult.downloadInfo().downloaded, aResult.downloadInfo().total);
        if (aResult.downloadInfo().total == aResult.downloadInfo().downloaded)
        {
            Firebase.printf("Download task: %s, complete!✅️\n", aResult.uid().c_str());
        }
    }

    if (aResult.uploadProgress())
    {
        Firebase.printf("Uploaded, task: %s, %d%s (%d of %d)\n", aResult.uid().c_str(), aResult.uploadInfo().progress, "%", aResult.uploadInfo().uploaded, aResult.uploadInfo().total);
        if (aResult.uploadInfo().total == aResult.uploadInfo().uploaded)
        {
            Firebase.printf("Upload task: %s, complete!✅️\n", aResult.uid().c_str());
            Serial.print("Download URL: ");
            Serial.println(aResult.uploadInfo().downloadUrl);
        }
    }
}



