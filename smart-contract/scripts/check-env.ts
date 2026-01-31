import "dotenv/config";

console.log("Checking ACCOUNT_PRIVATE_KEY:");
console.log("Value:", process.env.ACCOUNT_PRIVATE_KEY);
console.log("Length:", process.env.ACCOUNT_PRIVATE_KEY?.length);
console.log("Type:", typeof process.env.ACCOUNT_PRIVATE_KEY);