"use strict";

require("dotenv").config();

const fs = require("fs");

const { Client, Util } = require("./AtCoder-API-Wrapper/src");
const client = new Client();

const contestId = process.argv[2];
const problemId = process.argv[3];
const sorcePath = process.argv[4];
const providedLanguageHintString = process.argv[5]?.trim();
const defaultLanguageHintString = process.argv[6]?.trim();

(async function () {
  const [sourceCode, contest] = await Promise.all([
    fs.promises.readFile(sorcePath, "utf8"),
    (async () => {
      await client.login();
      return client.contests.fetch(contestId);
    })(),
  ]);

  let languageHints;
  if (providedLanguageHintString == "---") languageHints = Util.extractLanguageHints(sourceCode);
  else languageHints = Util.splitLanguageHintStringIntoFilterQueries(providedLanguageHintString);

  if (!languageHints || languageHints?.length <= 0) {
    if(defaultLanguageHintString == "---") languageHints = [ '---' ];
    else languageHints = Util.splitLanguageHintStringIntoFilterQueries(defaultLanguageHintString);
  }

  let matchedLanguages = await contest.languages.filterBySelectors(languageHints);

  let languageId;

  if (matchedLanguages?.size > 0) {
    languageId = matchedLanguages.first().id;
  } else {
    throw new Error("Invalid language hints are provided.");
  }

  console.info(languageHints, languageId);

  await contest.submit(problemId, languageId, sourceCode)
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
