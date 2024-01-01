import cors = require("cors");
import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
//import { database } from "firebase-admin";
const excel = require("node-excel-export");

const corsHandler = cors({ origin: true });

admin.initializeApp();
const db = admin.firestore();
const fieldValue = admin.firestore.FieldValue;

const messageNewRequest = {
  title: "¡Te han enviado una solicitud!",
  message: "Recuerda que tienes máximo 2 horas para aceptarla ⏳.",
  include_player_ids: [],
};

const messageOnGoing = {
  title: "Comienza tu trabajo en ",
  message:
    "Has llegado a tu punto de trabajo, recuerda marcar la solicitud como finalizada en el lugar una vez termines.😉",
  include_player_ids: [],
};

const messageCanceled = {
  title: " ha cancelado la solicitud",
  message: "No desesperes!, pronto podrás recibir nuevos trabajos!.💪",
  include_player_ids: [],
};

const messageRefused = {
  title: "Se ha rechazado una solicitud automáticamente 😞",
  message:
    "Oh no!, dejaste pasar una oportunidad. Recuerda desactivarte si no puedes recibir solicitudes.",
  include_player_ids: [],
};

const messageReminder = {
  title: "Recuerda que tienes un turno para mañana! 😎",
  message: "Tienes una solicitud para trabajar ",
  include_player_ids: [],
};

const messageSpamReminder = {
  title: "Tienes una solicitud pendiente por aceptar!",
  message:
    "No dejes pasar esta oportunidad!, ingresa a HUTS y empieza a prestar tus servicios 😉",
  include_player_ids: [],
};

export const updateUser = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const uid = request.body.uid;
        const phone = request.body.phone;
        const prefixPhone = request.body.prefix;

        let toUpdate = {} as any;

        toUpdate = { phoneNumber: prefixPhone + phone };

        admin
          .auth()
          .updateUser(uid, toUpdate)
          .then(async () => {
            console.log("Successfully updates user:", uid);
            await db
              .collection("employees")
              .doc(uid)
              .update({ "profile_info.phone": phone })
              .then(function () {
                console.log("Successfully updated user firestore:");
                response.status(200).send({ uid: uid });
              })
              .catch((error) => {
                console.log("Error updating user firestore:", error);
                response.status(500).send({ error: error });
              });
            response.status(200).send("success");
          })
          .catch(function (error) {
            console.log("Error updating user auth:", error);
            response.status(500).send({ error: error });
          });
      } catch (error) {
        response.send(500).send({ status: error });
      }
    });
  }
);

exports.onChangeRequest = functions.firestore
  .document("requests/{requestId}")
  .onUpdate(async (change, context) => {
    messageCanceled.include_player_ids = [];
    messageNewRequest.include_player_ids = [];
    messageOnGoing.include_player_ids = [];
    messageRefused.include_player_ids = [];
    const newData = change.after.data();
    const previousData = change.before.data();

    let finalMessage = {} as any;

    if (newData["details"]["status"] == previousData["details"]["status"]) {
      return;
    }

    switch (newData["details"]["status"]) {
      case 1:
        //Asignada
        finalMessage = messageNewRequest;
        break;
      case 3:
        //En proceso
        messageOnGoing.title =
          "Comienza tu trabajo en " + newData["client_info"]["name"];
        finalMessage = messageOnGoing;
        break;
      case 5:
        //En proceso
        messageCanceled.title =
          newData["client_info"]["name"] + ' ha cancelado la solicitud"';
        finalMessage = messageCanceled;
        break;
      case 6:
        finalMessage = messageRefused;
        break;
      default:
        break;
    }

    if (!("message" in finalMessage)) return;

    const employeeDoc = await db
      .collection("employees")
      .doc(newData.employee_info.id)
      .get();

    if (employeeDoc.exists) {
      if (
        "notification_ids" in employeeDoc.data()!["account_info"] &&
        employeeDoc.data()!["account_info"]["notification_ids"].length != 0
      ) {
        finalMessage["user_uid"] = newData.employee_info.id;
        console.log(finalMessage);
        const notificationIds =
          employeeDoc.data()!["account_info"]["notification_ids"];
        if (notificationIds == undefined || notificationIds.length == 0) return;
        await sendNotification(finalMessage, notificationIds);
      }
    }
  });

async function sendNotification(template: any, notificationIds: any) {
  try {
    const body = {
      tokens: [],
      notification: {
        title: template.title,
        body: template.message,
      },
      android: {
        notification: {
          sound: "default",
        },
      },
      apns: {
        payload: {
          aps: {
            sound: "default",
          },
        },
      },
    };

    body.tokens = notificationIds;

    console.log(body.tokens);

    if (body.tokens.length > 0) {
      console.log(body.tokens);
      await admin
        .messaging()
        .sendMulticast(body)
        .then(() => {
          console.log("Notification sent successfully");
        })
        .catch((error) => {
          console.log("sendNotification error: " + error);
        });
      console.log("Successfully sent message");
    }
  } catch (error) {
    console.log("Error sending message: " + error);
  }
}

export const sendTomorrowReminder = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const today = new Date();
        const tomorrowStart = new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate() + 1,
          0,
          0
        );
        const tomorrowEnd = new Date(
          today.getFullYear(),
          today.getMonth(),
          today.getDate() + 1,
          23,
          59
        );

        //Search all requests for tomorrow that have been ACCEPTED.
        await db
          .collection("requests")
          .where("details.start_date", "<=", tomorrowStart)
          .where("details.start_date", ">=", tomorrowEnd)
          .where("details.status", "==", 2)
          .get()
          .then(async (myQuery) => {
            for (let index = 0; index < myQuery.docs.length; index++) {
              const myDoc = myQuery.docs[index];
              const dataDoc = myDoc.data();
              let finalMessage = {} as any;

              const employeeDoc = await db
                .collection("employees")
                .doc(dataDoc["employee_info"]["id"])
                .get();

              if (employeeDoc.exists) {

                if (
                  "notification_ids" in employeeDoc.data()!["account_info"] &&
                  employeeDoc.data()!["account_info"]["notification_ids"].length != 0
                ) {
                  messageReminder.include_player_ids = [];
                  const timeRequest = new Date(
                    dataDoc["details"]["start_date"] * 1000
                  ).toLocaleTimeString();
                  messageReminder.message =
                    messageReminder.message +
                    dataDoc["client_info"]["name"] +
                    " como " +
                    dataDoc["details"]["job"]["name"] +
                    " a las " +
                    timeRequest;
                  finalMessage = messageReminder;
                  await sendNotification(
                    finalMessage,
                    employeeDoc.data()!["account_info"]["notification_ids"]
                  );
                }
              }
            }
          });
        response.status(200).send("success");
      } catch (error) {
        console.log("Error sending message: " + error);
        response.status(500).send({ error: error });
      }
    });
  }
);

export const sendPendingRequestSpamReminder = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        await db
          .collection("requests")
          .where("details.status", "==", 1)
          .get()
          .then(async (myQuery) => {
            for (let index = 0; index < myQuery.docs.length; index++) {

              const myDoc = myQuery.docs[index];
              const dataDoc = myDoc.data();

              if (!("employee_info" in dataDoc)) continue;
              if (!("id" in dataDoc["employee_info"])) continue;
              if (dataDoc["employee_info"]["id"] == "") continue;

              let finalMessage = {} as any;
              messageSpamReminder.include_player_ids = [];
              finalMessage = messageSpamReminder;

              const employeeDoc = await db
                .collection("employees")
                .doc(dataDoc["employee_info"]["id"])
                .get();

              if (employeeDoc.exists) {
                if (
                  "notification_ids" in employeeDoc.data()!["account_info"] &&
                  employeeDoc.data()!["account_info"]["notification_ids"].length != 0
                ) {
                  await sendNotification(
                    finalMessage,
                    employeeDoc.data()!["account_info"]["notification_ids"]
                  );
                }
              }
            }
          });
        response.status(200).send("success");
      } catch (error) {
        console.log("Error sending message: " + error);
        response.status(500).send({ error: error });
      }
    });
  }
);

export const deleteAccount = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const uid = request.body.uid;
        console.log(uid);
        let userDeletedCopy = {};
        admin
          .auth()
          .deleteUser(uid)
          .then(async () => {
            console.log("create employee backup", uid);
            await db
              .collection("employees")
              .doc(uid)
              .get()
              .then(async (userDoc) => {
                const userData = userDoc.data();
                if (userData != null) {
                  userDeletedCopy = userData;

                  await db
                    .collection("deleted_employees")
                    .doc(uid)
                    .set(userDeletedCopy)
                    .then(async function () {
                      console.log("exit to copy user");
                      const documentRef = db.collection("employees").doc(uid);
                      await db.recursiveDelete(documentRef);
                      response.status(200).send({ uid: uid });
                    })
                    .catch((error) => {
                      console.log("fail to copy  user firestore:", error);
                      response.status(500).send({ error: error });
                    });
                }
              });
          })
          .catch((error) => {
            console.log("failed to delete user auth:", error);
            response.status(500).send({ error: error });
          });
      } catch (error) {
        response.status(500).send({ error: error });
      }
    });
  }
);

export const exportToExcel = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const headersFrom = request.body.headers;
        const headersforClient = request.body.headers_for_client;
        const excelInfoData = request.body.data;
        const excelInfoDataEvent = request.body.data_event;
        const otherInfo = request.body.other_info;
        const fileName = request.body.file_name;
        const dataset: any = [];
        const datasetEvent: any = [];
        const forClient = request.body.for_client;
        console.log(headersFrom);
        console.log(excelInfoData);
        console.log(otherInfo);
        console.log(fileName);
        console.log("-----");
        console.log(request.body);
        const styles = {
          headerDark: {
            fill: {
              fgColor: {
                rgb: "FF00A9A5",
              },
            },
            font: {
              color: {
                rgb: "FFFFFFFF",
              },
              sz: 14,
              bold: true,
            },
          },
        };
        const specification: any = {
          /*id: {
                        displayName: 'ID',
                        width: 300,
                        headerStyle: styles.headerDark,

                    }*/
        };

        for (let index = 0; index < headersFrom.length; index++) {
          const item = headersFrom[index];
          specification[item.key] = {
            displayName: item.display_name,
            width: item.width,
            headerStyle: styles.headerDark,
          };
        }
        for (let index = 0; index < excelInfoData.length; index++) {
          const element = excelInfoData[index];
          dataset.push(element);
        }
        if (forClient) {
          for (let index = 0; index < headersforClient.length; index++) {
            const item = headersforClient[index];
            specification[item.key] = {
              displayName: item.display_name,
              width: item.width,
              headerStyle: styles.headerDark,
            };
          }
          for (let index = 0; index < excelInfoDataEvent.length; index++) {
            const element = excelInfoDataEvent[index];
            datasetEvent.push(element);
          }
        }

        console.log(dataset);
        console.log(datasetEvent);
        var report;
        if (!forClient) {
          report = excel.buildExport([
            {
              name: fileName,
              merges: [],
              specification: specification,
              data: dataset,
            },

          ]);
        } else {
          report = excel.buildExport([
            {
              name: fileName,
              merges: [],
              specification: specification,
              data: dataset,
            },
            {
              name: 'Por evento',
              merges: [],
              specification: specification,
              data: datasetEvent,
            },
          ]);
        }
        response.status(200).send({ report: report });
      } catch (error) {
        console.log("Error exportToExcel " + error);
        response.status(500).send({ status: error });
      }
    });
  }
);

export const findEmployeesToPendingRequests = functions
  .runWith({
    timeoutSeconds: 540,
    memory: "2GB",
  })
  .https.onRequest(async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const clientsInfo: any = {};
        const currentDate: Date = new Date();

        //Get all pending requests//
        const requestsQuerysnapshot = await db
          .collection("requests")
          .where("details.status", "==", 0)
          .where("details.start_date", ">=", currentDate)
          .get();

        console.log(
          `Requests to find employees length: ${requestsQuerysnapshot.docs.length}`
        );

        //Group requests by client//
        for (let i = 0; i < requestsQuerysnapshot.docs.length; i++) {
          const requestData = requestsQuerysnapshot.docs[i].data();

          const clientId = requestData.client_info.id;

          if (clientId in clientsInfo) {
            clientsInfo[clientId].requests.push(requestData);
          } else {
            const clientQuery = await db
              .collection("clients")
              .where("account_info.id", "==", clientId)
              .get();

            const clientData = clientQuery.docs[0].data();

            clientsInfo[clientId] = {
              favoriteEmployees: clientData["favorites_employees"],
              blockedEmployees: clientData["blocked_employees"],
              requests: [requestData],
            };
          }
        }

        console.log("clientsInfo:");
        console.log(clientsInfo);

        //Get employees and try to assign them to every client request //
        for (let j = 0; j < Object.keys(clientsInfo).length; j++) {
          const client = clientsInfo[Object.keys(clientsInfo)[j]];
          for (let k = 0; k < client.requests.length; k++) {
            let possibleEmployees: Array<any> = [];
            const jobRequest = client.requests[k];

            const job = jobRequest.details.job.value;

            const startDate: Date = jobRequest.details.start_date.toDate();
            const endDate: Date = jobRequest.details.end_date.toDate();
            const startDay: number =
              startDate.getDay() == 0 ? 6 : startDate.getDay() - 1;
            const startHours: number = startDate.getHours();
            const workShift: string =
              startHours > 6 && startHours <= 12
                ? "morning_shift_enabled"
                : startHours > 12 && startHours <= 22
                  ? "afternoon_shift_enabled"
                  : "night_shift_enabled";

            //Get employees//
            const employeesQuerySnapshot = await db
              .collection("employees")
              .where("jobs", "array-contains", job)
              .where("account_info.status", ">=", 1)
              .where("account_info.status", "<", 3)
              .get();

            //If not employees were found, continues with next iteration//
            if (employeesQuerySnapshot.docs.length == 0) continue;

            //Possible employees list//
            possibleEmployees = [
              ...employeesQuerySnapshot.docs.map((doc) => {
                const employeeData = doc.data();
                employeeData["is_favorite"] = false;
                return employeeData;
              }),
            ];

            const possibleEmployeesCopy = [...possibleEmployees];

            //Delete employees that did not accept the request
            possibleEmployeesCopy.forEach((employeeItem) => {
              if (
                "last_cancelled_request" in employeeItem.account_info &&
                employeeItem.account_info["last_cancelled_request"] ==
                jobRequest.id
              ) {
                const indexx: number = possibleEmployees.indexOf(employeeItem);
                possibleEmployees.splice(indexx, 1);
              }
            });

            //Delete not workshift avaliable employees//
            possibleEmployeesCopy.forEach((employeeItem) => {
              if (!employeeItem.availability[startDay][workShift]) {
                const indexx: number = possibleEmployees.indexOf(employeeItem);
                possibleEmployees.splice(indexx, 1);
              }
            });

            //Delete client bocked employees//
            for (const key in client.blockedEmployees) {
              if (
                Object.prototype.hasOwnProperty.call(
                  client.blockedEmployees,
                  key
                )
              ) {
                const employeeId1: string = key;
                const employeeIndex1: number = possibleEmployees.findIndex(
                  (element1) => element1.uid == employeeId1
                );
                if (employeeIndex1 != -1) {
                  possibleEmployees.splice(employeeIndex1, 1);
                }
              }
            }

            //Set possible employees favorite value//

            for (const key2 in client.favoriteEmployees) {
              if (
                Object.prototype.hasOwnProperty.call(
                  client.favoriteEmployees,
                  key2
                )
              ) {
                const employeeId2: string = key2;
                const employeeIndex2: number = possibleEmployees.findIndex(
                  (element2) => element2.uid == employeeId2
                );
                if (employeeIndex2 != -1) {
                  possibleEmployees[employeeIndex2]["is_favorite"] = true;
                }
              }
            }

            //Sort possible employees list by favorite and rate values//

            //Employees that are favorite and have a good calification
            let favoriteAndCalificationEmployees: Array<any> = [];
            //Employees that are favorite and have a bad calification
            let favoriteEmployees: Array<any> = [];
            //Employees that are not favorite and have a good calification
            let notFavoriteCalificationEmployees: Array<any> = [];
            //Employees that are not favorite and have a bad calification
            let notFavoriteNotCalificationEmployees: Array<any> = [];

            favoriteAndCalificationEmployees = [
              ...possibleEmployees.filter(
                (employee) =>
                  (employee["is_favorite"] &&
                    "rate" in employee["profile_info"] &&
                    employee["profile_info"]["rate"]["general_rate"] >= 4) ||
                  (employee["is_favorite"] &&
                    !("rate" in employee["profile_info"]))
              ),
            ];

            favoriteEmployees = [
              ...possibleEmployees.filter(
                (employee2) =>
                  employee2["is_favorite"] &&
                  "rate" in employee2["profile_info"] &&
                  employee2["profile_info"]["rate"]["general_rate"] < 4
              ),
            ];

            favoriteEmployees.sort(
              (a, b) =>
                b["profile_info"]["rate"]["general_rate"] -
                a["profile_info"]["rate"]["general_rate"]
            );

            notFavoriteCalificationEmployees = [
              ...possibleEmployees.filter(
                (employee3) =>
                  (!employee3["is_favorite"] &&
                    "rate" in employee3["profile_info"] &&
                    employee3["profile_info"]["rate"]["general_rate"] >= 4) ||
                  (!employee3["is_favorite"] &&
                    !("rate" in employee3["profile_info"]))
              ),
            ];

            notFavoriteNotCalificationEmployees = [
              ...possibleEmployees.filter(
                (employee4) =>
                  !employee4["is_favorite"] &&
                  "rate" in employee4["profile_info"] &&
                  employee4["profile_info"]["rate"]["general_rate"] < 4
              ),
            ];

            notFavoriteNotCalificationEmployees.sort(
              (a, b) =>
                b["profile_info"]["rate"]["general_rate"] -
                a["profile_info"]["rate"]["general_rate"]
            );

            possibleEmployees = [
              ...favoriteAndCalificationEmployees.concat(
                favoriteEmployees,
                notFavoriteCalificationEmployees,
                notFavoriteNotCalificationEmployees
              ),
            ];

            console.log(
              "possibleEmployees lenght: " + possibleEmployees.length
            );

            //Validate possible employees by them requests//
            for (let l = 0; l < possibleEmployees.length; l++) {
              const possibleEmployee = possibleEmployees[l];

              let possibleEmployeeRequests: Array<any> = [];

              const employeeRequestsQuery = await db
                .collection("requests")
                .where("employee_info.id", "==", possibleEmployee.uid)
                .where("details.status", ">=", 1)
                .where("details.status", "<", 4)
                .get();

              possibleEmployeeRequests = [
                ...employeeRequestsQuery.docs.map((requestDoc) => {
                  const requestData = requestDoc.data();
                  requestData["start_date"] =
                    requestData.details["start_date"].toDate();
                  requestData["end_date"] =
                    requestData.details["end_date"].toDate();
                  return requestData;
                }),
              ];

              let isEmployeeAvailable = true;

              for (let m = 0; m < possibleEmployeeRequests.length; m++) {
                const employeeRequest = possibleEmployeeRequests[m];
                if (
                  employeeRequest["start_date"] >= startDate &&
                  employeeRequest["end_date"] <= endDate
                ) {
                  isEmployeeAvailable = false;
                  break;
                }

                if (
                  startDate >= employeeRequest["start_date"] &&
                  endDate <= employeeRequest["end_date"]
                ) {
                  isEmployeeAvailable = false;
                  break;
                }

                if (
                  startDate >= employeeRequest["start_date"] &&
                  startDate <= employeeRequest["end_date"] &&
                  endDate >= employeeRequest["end_date"]
                ) {
                  isEmployeeAvailable = false;
                  break;
                }

                if (
                  employeeRequest["start_date"] >= startDate &&
                  employeeRequest["start_date"] <= endDate &&
                  employeeRequest["end_date"] >= endDate
                ) {
                  isEmployeeAvailable = false;
                  break;
                }
              }

              if (isEmployeeAvailable) {
                const foodDoc =
                  possibleEmployee.documents.manipulacion_de_alimentos ?? {};
                const covidDoc =
                  possibleEmployee.documents.carne_vacunas_covid ?? {};

                // const currentDate = new Date();

                const expDate = new Date();

                expDate.setHours(expDate.getHours() + 2);

                await db
                  .collection("requests")
                  .doc(jobRequest.id)
                  .update({
                    employee_info: {
                      id: possibleEmployee.uid,
                      doc_type: possibleEmployee.profile_info.doc_type,
                      doc_number: possibleEmployee.profile_info.doc_number,
                      image: possibleEmployee.profile_info.image,
                      names: possibleEmployee.profile_info.names,
                      last_names: possibleEmployee.profile_info.last_names,
                      full_name:
                        possibleEmployee.profile_info.names +
                        " " +
                        possibleEmployee.profile_info.last_names,
                      phone: possibleEmployee.profile_info.phone,
                      manipulacion_de_alimentos: foodDoc,
                      carne_de_vacunas_covid: covidDoc,
                      exp_date: expDate,
                    },
                    "details.status": 1,
                  });
                console.log("Employee added to a request, request id:");
                console.log(jobRequest.id);
                break;
              } else {
                console.log("No available employee, next iteration");
                continue;
              }
            }
          }
        }

        response.send({ status: "OK" });
      } catch (error) {
        console.log("findEmployees error: " + error);
        response.status(500).send({ status: "FAIL" });
      }
    });
  });

export const sendEventMessage = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const messageData = request.body;

        const messageBody = {
          tokens: [],
          notification: {
            title: messageData.title,
            body: messageData.message,
          },
          android: {
            notification: {
              sound: "default",
            },
          },
          apns: {
            payload: {
              aps: {
                sound: "default",
              },
            },
          },
        };

        const employeesIds: Array<string> =
          messageData.employees_ids.split(",");
        const filesUrls: Array<string> =
          messageData.files_urls == "" ? [] : messageData.files_urls.split(",");

        const finalDestinataries: Array<any> = [];

        for (let index = 0; index < employeesIds.length; index++) {
          const employeeId = employeesIds[index];
          const employeeData = (
            await db.collection("employees").doc(employeeId).get()
          ).data() ?? { account_info: { notification_ids: [] } };
          if (employeeData["account_info"]["notification_ids"].length == 0) {
            continue;
          }
          messageBody.tokens = [
            ...messageBody.tokens.concat(
              employeeData["account_info"]["notification_ids"]
            ),
          ];
          finalDestinataries.push({
            id: employeeId,
            data: employeeData["profile_info"],
          });
        }
        if (messageBody.tokens.length > 0) {
          await admin
            .messaging()
            .sendMulticast(messageBody)
            .then(async () => {
              let currentDate: Date = new Date();
              currentDate.setHours(currentDate.getHours());

              await db
                .collection("messages")
                .doc(messageData.message_id)
                .set({
                  id: messageData.message_id,
                  date: currentDate,
                  from: messageData.from,
                  title: messageData.title,
                  message: messageData.message,
                  attached_files_urls: filesUrls,
                  type: messageData.type,
                  formatted_date: `${currentDate.getDate()}-${currentDate.getMonth() + 1
                    }-${currentDate.getFullYear()}`,
                });
              let batch = db.batch();
              let counter = 0;
              for await (const destinatary of finalDestinataries) {
                counter++;
                if (counter <= 500) {
                  const ref = db
                    .collection("messages")
                    .doc(messageData.message_id)
                    .collection("employees")
                    .doc(destinatary["id"]);
                  batch.set(ref, {
                    employee_id: destinatary["id"],
                    employee_names: destinatary["data"]["names"],
                    employee_last_names: destinatary["data"]["last_names"],
                    message_date: currentDate,
                    message_type: messageData.type,
                    is_visible: true,
                    is_read: false,
                  });
                } else {
                  await batch.commit();
                  batch = db.batch();
                  const ref = db
                    .collection("messages")
                    .doc(messageData.message_id)
                    .collection("employees")
                    .doc(destinatary["id"]);
                  batch.set(ref, {
                    employee_id: destinatary["id"],
                    employee_names: destinatary["data"]["names"],
                    employee_last_names: destinatary["data"]["last_names"],
                    message_date: currentDate,
                    message_type: messageData.type,
                    is_visible: true,
                    is_read: false,
                  });
                  counter = 1;
                }
              }

              await batch.commit();

              console.log("Message sent successfully");
              response.send({ status: "SUCCESS" });
            })
            .catch((error) => {
              console.log(`sendEventMessage error: ${error}`);
              response.status(500).send({ status: "FAIL" });
            });
        } else {
          response.sendStatus(200);
        }
      } catch (error) {
        console.log(`sendEventMessage error: ${error}`);
        response.status(500).send({ status: "FAIL" });
      }
    });
  }
);

export const enableDisableEmployee = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const employeeId = request.body.id;
        const toDisable = request.body.to_disable;
        const newStatus = request.body.new_status;

        admin
          .auth()
          .updateUser(employeeId, {
            disabled: toDisable,
          })
          .then(async () => {
            console.log("Successfully update employee:", employeeId);
            await db
              .collection("employees")
              .doc(employeeId)
              .update({ "account_info.status": newStatus })
              .then(function () {
                console.log("Successfully updated employee firestore:");
                response.status(200).send({ uid: employeeId });
              })
              .catch((error) => {
                console.log("Error updating employee firestore:", error);
                response.status(500).send({ error: error });
              });
          })
          .catch(function (error) {
            console.log("Error updating employee auth:", error);
            response.status(500).send({ error: error });
          });
      } catch (error) {
        response.status(500).send({ status: error });
      }
    });
  }
);

export const createAdmin = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const data = request.body;
        data.account_info.creation_date = new Date();
        admin
          .auth()
          .createUser({
            email: data.profile_info.email,
            emailVerified: true,
            password: data.password,
            displayName:
              data.profile_info.names + " " + data.profile_info.last_names,
            disabled: false,
          })
          .then(async (userRecord) => {
            console.log("Successfully create admin:", userRecord.uid);
            data.uid = userRecord.uid;
            delete data.password;
            await db
              .collection("web_users")
              .doc(userRecord.uid)
              .set(data)
              .then(function () {
                console.log("Successfully created admin firestore:");
                response.status(200).send({ uid: userRecord.uid });
              })
              .catch((error) => {
                console.log("Error creating admin firestore:", error);
                response.status(500).send({ error: error });
              });
          })
          .catch(function (error) {
            console.log("Error creating admin auth:", error);
            response.status(500).send({ error: error });
          });
      } catch (error) {
        response.status(500).send({ status: error });
      }
    });
  }
);

export const deleteAdmin = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const uid = request.body.uid;
        let userDeletedCopy = {};
        admin
          .auth()
          .deleteUser(uid)
          .then(async () => {
            console.log("create admin backup", uid);
            await db
              .collection("web_users")
              .doc(uid)
              .get()
              .then(async (userDoc) => {
                const userData = userDoc.data();
                if (userData != null) {
                  userDeletedCopy = userData;

                  await db
                    .collection("deleted_web_users")
                    .doc(uid)
                    .set(userDeletedCopy)
                    .then(async function () {
                      console.log("exit to copy user");
                      const documentRef = db.collection("web_users").doc(uid);
                      await db.recursiveDelete(documentRef);
                      response.status(200).send({ uid: uid });
                    })
                    .catch((error) => {
                      console.log("fail to copy  user firestore:", error);
                      response.status(500).send({ error: error });
                    });
                }
              });
          })
          .catch((error) => {
            console.log("failed to delete user auth:", error);
            response.status(500).send({ error: error });
          });
      } catch (error) {
        response.status(500).send({ error: error });
      }
    });
  }
);

export const updateWebUserAuth = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const uid = request.body.uid;
        const email = request.body.email;
        const password = request.body.password;

        let updatedata =
          password != ""
            ? { email: email, password: password }
            : { email: email };

        admin
          .auth()
          .updateUser(uid, updatedata)
          .then(async () => {
            console.log("Successfully updateWebUserAuth:", uid);
            await db
              .collection("web_users")
              .doc(uid)
              .update({ "profile_info.email": email })
              .then(function () {
                console.log("Successfully updateWebUserAuth firestore:");
                response.status(200).send({ uid: uid });
              })
              .catch((error) => {
                console.log("Error updateWebUserAuth firestore:", error);
                response.status(500).send({ error: error });
              });
          })
          .catch(function (error) {
            console.log("Error uupdateWebUserAuth auth:", error);
            response.status(500).send({ error: error });
          });
      } catch (error) {
        response.status(500).send({ status: error });
      }
    });
  }
);

export const unlockEmployees = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const querySnapShot = await db
          .collection("employees")
          .where("account_info.status", ">=", 3)
          .where("account_info.status", "<=", 6)
          .get();

        const currentDate = new Date();
        const batch = db.batch();

        querySnapShot.docs.forEach((doc) => {
          const data = doc.data();

          if (
            data["account_info"]["status"] == 3 ||
            data["account_info"]["status"] == 6
          ) {
            if (data["account_info"]["unlock_date"].toDate() <= currentDate) {
              const ref = db.collection("employees").doc(doc.id);
              batch.update(ref, { "account_info.status": 1 });
            }
          }
        });
        await batch.commit();
        console.log("Employees unlocked successfully");
        response.send({ status: "SUCCESS" });
      } catch (error) {
        console.log("unlockEmployees error: " + error);
        response.status(500).send({ status: error });
      }
    });
  }
);

export const updateNotAcceptedRequests = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        //Get pending requests//
        const querySnapShot = await db
          .collection("requests")
          .where("details.status", "==", 1)
          .get();

        console.log("Pending requests: " + querySnapShot.size);

        const currentDate = new Date();
        const currentMonth = currentDate.getMonth() + 1;
        const requestsBatch = db.batch();
        const employeesBatch = db.batch();

        const initialMonthsMap = {
          "1": { lock_times: 0 },
          "2": { lock_times: 0 },
          "3": { lock_times: 0 },
          "4": { lock_times: 0 },
          "5": { lock_times: 0 },
          "6": { lock_times: 0 },
          "7": { lock_times: 0 },
          "8": { lock_times: 0 },
          "9": { lock_times: 0 },
          "10": { lock_times: 0 },
          "11": { lock_times: 0 },
          "12": { lock_times: 0 },
        };

        //Loop pending requests//
        for (let index = 0; index < querySnapShot.docs.length; index++) {
          const requestDoc = querySnapShot.docs[index];
          let requestData = requestDoc.data();

          console.log(requestData["employee_info"]);

          //Validate if the request has exp_date field and is expired//
          if (!("exp_date" in requestData["employee_info"])) continue;

          console.log(requestData["employee_info"]["exp_date"].toDate());
          console.log(currentDate);

          if (requestData["employee_info"]["exp_date"].toDate() > currentDate) {
            continue;
          }

          console.log("Request to update");

          //Update request status//
          const requestRef = db.collection("requests").doc(requestDoc.id);
          requestsBatch.update(requestRef, {
            employee_info: {},
            "details.status": 0,
          });

          //Validate if employee has to be blocked//

          //Get employee data//
          const employeeDoc = await db
            .collection("employees")
            .doc(requestData["employee_info"]["id"])
            .get();

          if (!employeeDoc.exists) continue;

          const employeeData = employeeDoc.data() ?? { account_info: {} };

          const employeeRef = db.collection("employees").doc(employeeDoc.id);

          //When the employee has a previous lock//
          if ("locked_by_requests_info" in employeeData["account_info"]) {
            //When the new lock is at the same month at the previous//
            if (
              employeeData["account_info"]["locked_by_requests_info"][
              "current_month_lock"
              ] == currentMonth
            ) {
              const unlockDate = currentDate;

              unlockDate.setHours(
                unlockDate.getHours() +
                employeeData["account_info"]["locked_by_requests_info"][
                "locked_times"
                ] *
                2
              );
              employeesBatch.update(employeeRef, {
                "account_info.locked_by_requests_info.locked_times":
                  fieldValue.increment(1),
                "account_info.unlock_date": unlockDate,
                "account_info.status": 3,
                last_cancelled_request: requestDoc.id,
              });

              const lockHistoricalRef = db
                .collection("employees")
                .doc(employeeDoc.id)
                .collection("lock_history")
                .doc(currentDate.getFullYear().toString());

              const currentYearHistoryDoc = await lockHistoricalRef.get();

              if (currentYearHistoryDoc.exists) {
                const key = `${currentMonth.toString()}.lock_times`;

                employeesBatch.update(lockHistoricalRef, {
                  [key]: fieldValue.increment(1),
                });
              } else {
                let employeeMonthsMap: any = { ...initialMonthsMap };

                employeeMonthsMap[currentMonth.toString()]["lock_times"] += 1;

                employeesBatch.set(lockHistoricalRef, employeeMonthsMap);
              }
            } else {
              employeesBatch.update(employeeRef, {
                "account_info.locked_by_requests_info.locked_times": 1,
                "account_info.locked_by_requests_info.current_month_lock":
                  currentMonth,
              });

              const currentYearHistoryRef = db
                .collection("employees")
                .doc(employeeDoc.id)
                .collection("lock_history")
                .doc(currentDate.getFullYear().toString());

              const currentYearHistoryDoc = await currentYearHistoryRef.get();

              if (currentYearHistoryDoc.exists) {
                const key = `${currentMonth.toString()}.lock_times`;

                employeesBatch.update(currentYearHistoryRef, {
                  [key]: fieldValue.increment(1),
                });
              } else {
                let employeeMonthsMap: any = { ...initialMonthsMap };

                employeeMonthsMap[currentMonth.toString()]["lock_times"] += 1;

                employeesBatch.set(currentYearHistoryRef, employeeMonthsMap);
              }
            }
          } else {
            //When the employee does not have a previous lock//
            employeesBatch.update(employeeRef, {
              "account_info.locked_by_requests_info": {
                locked_times: 1,
                current_month_lock: currentMonth,
              },
            });

            const lockHistoricalRef = db
              .collection("employees")
              .doc(employeeDoc.id)
              .collection("lock_history")
              .doc(currentDate.getFullYear().toString());

            let employeeMonthsMap: any = { ...initialMonthsMap };

            employeeMonthsMap[currentMonth.toString()]["lock_times"] += 1;

            employeesBatch.set(lockHistoricalRef, employeeMonthsMap);
          }
        }

        await requestsBatch.commit();
        await employeesBatch.commit();

        response.status(200).send("success");
      } catch (error) {
        console.log("updateNotAcceptedRequests error: " + error);
        response.status(500).send({ status: error });
      }
    });
  }
);

export const updateUserClient = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const updateData = request.body;

        const hasToUpdateAuth =
          "password" in updateData || "email" in updateData;

        if (hasToUpdateAuth) {
          let authData: any = {};
          if ("password" in updateData) {
            authData["password"] = updateData["password"];
          }
          if ("email" in updateData) {
            authData["email"] = updateData["email"];
          }

          admin
            .auth()
            .updateUser(updateData["uid"], authData)
            .then(async () => {
              console.log(
                "updateUserClient, user auth updated succesfully, uid:" +
                updateData["uid"]
              );
              await db.collection("web_users").doc(updateData["uid"]).update({
                "profile_info.names": updateData["names"],
                "profile_info.last_names": updateData["last_names"],
                "profile_info.phone": updateData["phone"],
                "profile_info.email": updateData["email"],
                "profile_info.image": updateData["image_url"],
                "account_info.subtype": updateData["subtype"],
              });

              const updateEmailKey = `web_users.${updateData["uid"]}.email`;
              const updatefullNameKey = `web_users.${updateData["uid"]}.full_name`;
              const updatePhoneKey = `web_users.${updateData["uid"]}.phone`;
              const updateSubTypeKey = `web_users.${updateData["uid"]}.subtype`;
              const updateImageKey = `web_users.${updateData["uid"]}.image`;
              if (updateData["client_id"] != "") {
                await db
                  .collection("clients")
                  .doc(updateData["client_id"])
                  .update({
                    [updateEmailKey]: updateData["email"],
                    [updatefullNameKey]:
                      updateData["names"] + " " + updateData["last_names"],
                    [updatePhoneKey]: updateData["phone"],
                    [updateSubTypeKey]: updateData["subtype"],
                    [updateImageKey]: updateData["image_url"],
                  });
              }
              response.status(200).send("success");

            })
            .catch(function (error) {
              console.log(
                "updateUserClient, error updating user auth, uid:" +
                updateData["uid"]
              );
              response.status(500).send({ error: error });
            });
        } else {
          await db.collection("web_users").doc(updateData["uid"]).update({
            "profile_info.names": updateData["names"],
            "profile_info.last_names": updateData["last_names"],
            "profile_info.phone": updateData["phone"],
            "profile_info.image": updateData["image_url"],
            "account_info.subtype": updateData["subtype"],
          });

          const updatefullNameKey = `web_users.${updateData["uid"]}.full_name`;
          const updatePhoneKey = `web_users.${updateData["uid"]}.phone`;
          const updateSubTypeKey = `web_users.${updateData["uid"]}.subtype`;
          const updateImageKey = `web_users.${updateData["uid"]}.image`;
          if (updateData["client_id"] != "") {
            await db
              .collection("clients")
              .doc(updateData["client_id"])
              .update({
                [updatefullNameKey]:
                  updateData["names"] + " " + updateData["last_names"],
                [updatePhoneKey]: updateData["phone"],
                [updateSubTypeKey]: updateData["subtype"],
                [updateImageKey]: updateData["image_url"],
              });
          }
          response.status(200).send("success");
        }
      } catch (error) {
        console.log("updateUserClient  error: " + error);
        response.status(500).send({ error: error });
      }
    });
  }
);

export const checkIfPhoneExists = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, () => {
      try {
        const phone = request.body.phone;
        admin
          .auth()
          .getUserByPhoneNumber(phone)
          .then(function (userRecord) {
            console.log(userRecord.uid);
            response.status(200).send({ exists: true });
          })
          .catch(function (error) {
            if (error.code === "auth/user-not-found") {
              response.status(200).send({ exists: false });
            }
            response.status(500).send({ error: error });
          });
      } catch (error) {
        console.log(`checkIfPhoneExists  error:   ${error}`);
        response.status(500).send({ error: error });
      }
    });
  }
);


export const finishActiveRequests = functions.https.onRequest(
  async (request, response) => {
    corsHandler(request, response, async () => {
      try {
        const currentDate: Date = new Date();
        const querySnapShot = await db.collection("requests").where("details.status", "==", 3).where("details.end_date", "<", currentDate).get();

        let batch = db.batch();
        let counter = 0;

        for await (const requestDoc of querySnapShot.docs) {
          counter++;
          if (counter <= 500) {
            const ref = db
              .collection("requests")
              .doc(requestDoc.id);
            batch.update(ref, {
              "details.status": 4,
              "details.departed_date": currentDate,
            });
          } else {
            await batch.commit();
            batch = db.batch();
            const ref = db
              .collection("requests")
              .doc(requestDoc.id);
            batch.update(ref, {
              "details.status": 4,
              "details.departed_date": currentDate,

            });
            counter = 1;
          }
        }
        await batch.commit();
        response.status(200).send("success");
      } catch (error) {
        console.log(`finishActiveRequests  error:   ${error}`);
        response.status(500).send({ error: error });
      }

    });

  }
);
