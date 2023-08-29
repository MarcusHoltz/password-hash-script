# Password Hash Script

Repeatable, unique passwords for every service or website

**The creation of different passwords for every service or website you're using can become a pain.**

> Using a repeatable method to generate these passwords, while remaining secure, can help speed up password creation and give you a system to finding lost passwords.

> Please keep in mind that hashing is a one way operation. 

- The hash generated is stored within the .passwords folder inside of a passworded zip file (the password used is the one chosen inside the script).

- The original plain text of the hash is stored in a passworded zip.

- At no point is anything unecrypted written to disk.


* * *

## Let's look into the script:

```
########################################################
#####          What does this script do?           #####
########################################################
## Inspired by: https://github.com/pashword/pashword ##
## This script hopes to create a hashed password     ##
## that cannot be found in a pre-generated table     ##
#######################################################
```

> ### Please read script information.

```
#######################################################
## This script requires 270MB of free RAM            ##
## Be sure you have installed:                       ##
##          zip, openssl, argon2                     ##
#######################################################
## What directory do you want to                     ## 
## store your password files in?                     ##
#######################################################
This is the only area in the script that would need
            user input for editing
--------------------------------------------------------
PASSWORD_FILES_LOCATION=~/Documents/.passwords
```


> Everything else prompts for input to generate the password hashes.


* * * 

## Visual representation of what the script does:
```
     ┌────────────┐     ┌───────────┐     ┌────────────┐
     │            │     │           │     │            │
     │            │     │           │     │ ┌────────┐ │
     │            │     │           │     │ │  I N   │ │
     │ U S E R    │     │           │     │ │ memory │ │
     │            ├────►│ Combined  ├────►│ │Password│ ├─┐
     │            │     │  U S E R  │     │ └────────┘ │ │
     │  I N P U T │     │ I N P U T │     │  TXT       │ │
     │            │     │           │     │  FORMAT    │ │
     └────────────┘     └───────────┘     └────────────┘ │
                                                         │
┌────────────────────────────────────────────────────────┘
│
│  ┌─────────────┐  ┌────────────┐  ┌─────────────────────────┐
│  │             │  │            │  │                         │
│  │ ┌─────────┐ │  │ ┌────────┐ │  │       ┌────────┐        │
│  │ │  I N    │ │  │ │  I N   │ │  │       │  I N   │        │
└─►│ │ memory  │ ├─►│ │ memory │ ├─►│       │ memory │        │
   │ │Password │ │  │ │Password│ │  │       │Password│        │
   │ └─────────┘ │  │ └────────┘ │  │       └────────┘        │
   │  SHA3-384   │  │  Argon2    │  │ Encrypted Zip Created   │
   │   H A S H   │  │  H A S H   │  │ txt & hash files inside │
   └─────────────┘  └────────────┘  └────────────────────┬────┘
                                                         │
 ┌───────────────────────────────────────────────────┐   │
 │                                                   │   │
 │ Finished  Argon2  Hash  is  reprinted  on  screen │◄──┘
 │                                                   │
 └───────────────────────────────────────────────────┘
```





## Explaining the choices within the script

```
###########################################
###      Why did I pick those values?    ##
###########################################
# Phrase - helps the user keep these passwords organized in their head. It's repeatable through multiple passwords.
# Age - random number data, but also, reminds the user to change their password yearly. If you try and hash 23 and it doesnt work, hash 22, and it does -- that reminds you to update the hash to this years age. 
# Service - Very important. This helps name all the files, is also used in the salt.
# Username - Should be different for each site. Also used for the salt.
###########################################
```


* * *

## In memory, never on disk

**Use a fifo (a named pipe), instead of writing to disk.** 

To do this, we'll be piping to stdin directly. 

The only gotcha is when the data is piped to fifo it needs to run in the background. We need this data to remain in memory for as long as the hashing takes -- before it can be encrypted.
Then just remove the file and it's gone from memory, never on disk.


* * *

## SHA then Argon2

User values are hashed, so one-way-encryption, first using SHA3-384 and then using the Argon2 algorithm the second time. This is to ensure maximum bruteforce and dictionary attack protection.

SHA3-384 was chosen due to Argon2's input size.


* * *

## Argon2 input size

128 minus 1 characters are supported in command line utility for Argon2. *So this means we have to use something smaller than 512 bits.*

- SHA3-384's hash is 384 bits long. 

- This will give us a nice long hash to send to our key derivation function.

Just for reference, maximum input length for bcrypt is 72 characters.


 * * *

## Argon2 settings

```
       -id             Use Argon2id instead of Argon2
       -t N            Sets the number of iterations to N (default = 3)
       -m N            Sets the memory usage of 2^N KiB (default 12)
       -k N            Sets the memory usage of N KiB (default 4096)
       -p N            Sets parallelism to N threads (default 1)
       -l N            Sets hash output length to N bytes (default 32)
       -e              Output only encoded hash
```

Setting maximum password length less than 128 characters is discouraged by OWASP. Yet, atleast 10% of the time I have to create a password... character limits. This is the reality, not the ideal.

In this example, we're using 32 bits. This creates a hash like MD5 or any other 32 character long hash, far from 128, but hopefully closer to any restrictive password policies you might encounter:

`-l 32`

kB and GB are like the metric system, but this software wants kibibytes. Directly under 1GB is 976562 kibibytes (a whole GB is 976562.5 kibibytes).  1 Gigabyte is equal to (10^9 / 2^10) kibibytes. You can specify this with: `-k 976562`

To specify memory in KiB use the `-m` flag. This uses 2^N KiB so, `-m 20` would be about one gigabyte (24576 bytes more), and `-m 18` is 268.44 MB.

`-id -e -t 256 -m 20 -p 64 -l 32`

The command above, would take my CPU 10 minutes to generate!

* * *

I maximum I want is, maybe, 30 seconds of patience. So we'll use 16 iterations, 270mb of memory, and 8 threads. 

This combination took my CPU (Passmark score of 5500) 7 seconds to generate.

Be sure to use the config below:

```bash
-id -e -t 16 -m 18 -p 8 -l 32
```

* * *

### Thanks! Good luck!
