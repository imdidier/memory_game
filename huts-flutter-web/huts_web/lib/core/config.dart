const isProduction = false;

const urlFunctions = (isProduction)
    ? "https://us-central1-huts-services.cloudfunctions.net"
    : "https://us-central1-huts-services.cloudfunctions.net"; /*"http://localhost:5001/huts-services/us-central1";*/

const endpointExportToExcel = "exportToExcel";
