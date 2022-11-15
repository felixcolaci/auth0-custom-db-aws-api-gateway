const users = {
  "carlos@atko.email": {
    password: "FliegendeFische",
    user_id: 123,
    given_name: "Carlos",
    family_name: "Caruso",
  },
};

module.exports.handler = async (event) => {
  console.log("Event: ", event);
  let responseMessage = "Hello, World!";

  try {
    const { username, password } = JSON.parse(event.body);

    const user = users[username];

    if (user && user.password === password) {
      return {
        statusCode: 200,
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ ...user, email: username, username }),
      };
    } else {
      throw new Error(`invalid credentials`);
    }
  } catch (error) {
    console.log(error);
    return {
      statusCode: 401,
      headers: {
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        message: `unauthorized: ${error}`,
      }),
    };
  }
};
