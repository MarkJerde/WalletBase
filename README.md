# Wallet Base

## What is this?
Wallet Base is an app which reads `swl` format encrypted information files. It does not create them but has some capacity to edit them.

## Why does this exist?
The software for that file format has long been out of production. I had a file I wanted to read and thought it would be a fun project to figure out the format and create a SwiftUI-based app to present the content. Since then it has just turned into a playground to practice SwiftUI and learn more about SQL, crypto, and other topics.

## So if you can read the encrypted file is it insecure?
Not at all. I know the password required to decrypt the content.

## So is the file secure?
Not really. It was fine for its time, but the form of AES (a good encryption mechanism) that it uses lacks some modern improvements which means it would be easier to crack. Also, and this depends on the content of the file, but it appears that in nearly all cases an attacker could use some analysis to find the encrypted form of text known to be the word "Password", which would be handy when identiying a simple target to check when attempting to crack the encryption. It might be reasonable to say that encrypting the names of common field types wasn't a good choice. But, you have one of these files and are trying to open it, so it's reasonable to assume you have already accepted the security of the file format. This software can now upgrade the encryption on the file, which is probably better than the original encryption, but it was written by a hack so there could be a big flaw somewhere in the upgraded encryption for all I know.

## Is this software safe?
It would require bad judgement for me to say it is safe. You read the code and decide how you feel about it. It certainly could be worse. It certainly could be better.

## How could it be better?
That's out of the scope of my expertise. I'm not trained in secure sensitive data management. Right now, decrypted content gets copied too much. It is limited, but if the decrypted content only existed in the C String that it initially decrypted to that would be better than moving it around in Swift String instances. C memory should also be securely wiped as soon as possible, which pretty much isn't happening at all right now and would go hand-in-hand with keeping decrypted content solely in C Strings. Once the encrypted content is limited to C String storage, a new View would be needed to render text directly from a C String ensuring there is no copying. Care should probably also be taken to avoid decrypted data being paged out to other storage. There are probably other cool best practicies for data security as well.

## What's up with the three-letter prefix? This isn't Objective-C.
The project is largely constructed to allow future storage and encryption mechanisms to be plugged in via Swift protocols. As the current content is for files with an `swl` file extension, the related files and some type names have an `Swl` prefix to specify the format they are for. Don't confuse it at all with traditional Objective-C naming prefixes as the purpose is entirely different.

## Why do the file names not always match the type names?
Swift does not allow multiple files with the same name, so when the `SwlDatabase` type contains a `Category` subtype and the hypothetical future `SuperSecureDatabase` type could also contain a `Category` subtype, the file names for both cannot simply be `Category.swift`. Naming it `SwlDatabaseCategory.swift` would be annoying since it is already in the `Database/Swl` group, so giving it a minimal unique prefix to differentiate the files is where we end up, with `SwlCategory.swift`.

## Can I contribute to the code?
Sure. Feel free to submit PRs to add features, add support for other file formats, add security, etc. As long as the code is clean and safe it'll probably be a good addition. Adding read-write support or OTP are perfectly welcome, to give some examples of what is not out-of-scope. Please use [SwitFormat](https://github.com/nicklockwood/SwiftFormat) with the default settings to format any files which are added or modified.

## How about more documentation?
Yes please. I have missed basic documentation in some places, but as little free time as I have for this project it would never be publicly released if I waited until I thought it was perfect.

## How about unit tests?
Yes please.
