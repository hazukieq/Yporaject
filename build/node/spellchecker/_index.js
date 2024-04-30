// C:\Users\{username}\AppData\Roaming\Typora\typora-dictionaries/user-dict.json
// ~/.config/Typora\typora-dictionaries/user-dict.json
// %AppData%\Microsoft\Spelling\en-US\default.dic

const spellCheckFactory = require("./lib/spellchecker");

spellCheckFactory.setUserDictionaryPath('C:\\Users\\leech\\AppData\\Roaming\\Typora\\typora-dictionaries');

const spellchecker = spellCheckFactory.getSpellChecker("en-US", true);

spellchecker.remove("TyporaY");
spellchecker.remove("TyporaX");

console.log("DONE!!");