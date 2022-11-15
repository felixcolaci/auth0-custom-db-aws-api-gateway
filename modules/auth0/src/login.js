function login(email, password, callback) {
  const AWS = require("aws-sdk@2.593.0");
  const https = require("https");
  const axios = require("axios");

  const ssm = new AWS.SSM({
    region: "eu-central-1",
    accessKeyId: configuration.aws_key_id,
    secretAccessKey: configuration.aws_secret,
  });

  const get_certificate_data = async () => {
    if (global.certificates) {
      return global.certificates;
    }

    try {
      const params = await ssm
        .getParameters({
          Names: [configuration.cert_name, configuration.key_name],
          WithDecryption: true,
        })
        .promise();

      const [cert, key] = params.Parameters.map((param) => param.Value);

      global.certificates = { cert, key };
      return global.certificates;
    } catch (error) {
      console.log(error);
      throw error;
    }
  };

  return get_certificate_data()
    .then((certData) => {
      const httpsAgent = new https.Agent(certData);
      return axios
        .post(`https://${configuration.api_base}/login`, { username: email, password }, { httpsAgent })
        .then((response) => {
          console.log(response.status);
          console.log(response.data);
          switch (response.status) {
            case 200:
              return callback(null, response.data);
            default:
              return callback(new WrongUsernameOrPasswordError(email));
          }
        })
        .catch((error) => {
          console.log(error);
          return callback();
        });
    })
    .catch((error) => {
      console.log(error);
      return callback(new WrongUsernameOrPasswordError(email));
    });
}
