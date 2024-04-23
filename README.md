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
## This script requires 135MB of free RAM            ##
## Be sure you have installed:                       ##
##       zip openssl argon2 gocryptfs fuse           ##
#######################################################
## What directory do you want to                     ## 
## store your password files in?                     ##
#######################################################
PASSWORD_FILES_LOCATION=~/Documents/.passwords
ENCRYPTED_PASSWORD_FILES_LOCATION=~/Documents/.passencrypted-on-disk
#######################################################
This is the only area in the script that would need
            user input for editing
--------------------------------------------------------
PASSWORD_FILES_LOCATION=~/Documents/.passwords
ENCRYPTED_PASSWORD_FILES_LOCATION=~/Documents/.passencrypted-on-disk
```


> Everything else prompts for input to generate the password hashes.


* * * 

## Visual representation of what the script does:
```
  ┌────────────────────────────────────────────────────┐
  │                                                    │
  │ gocryptfs directory created and password encrypted │
┌─┤                                                    │
│ └────────────────────────────────────────────────────┘
│
│
│    ┌────────────┐     ┌───────────┐     ┌────────────┐
│    │            │     │           │     │ ┌────────┐ │
│    │            │     │           │     │ │  I N   │ │
│    │ U S E R    │     │           │     │ │ memory │ │
└───►│            ├────►│ Combined  ├────►│ │Password│ ├─┐
     │            │     │  U S E R  │     │ └────────┘ │ │
     │  I N P U T │     │ I N P U T │     │  TXT       │ │
     │            │     │           │     │  FORMAT    │ │
     └────────────┘     └───────────┘     └────────────┘ │
                                                         │
┌────────────────────────────────────────────────────────┘
│
│  ┌─────────────┐  ┌────────────┐  ┌────────────────────┐
│  │ ┌─────────┐ │  │ ┌────────┐ │  │    unmounted       │
│  │ │  I N    │ │  │ │  I N   │ │  │    gocryptfs       │
│  │ │ memory  │ │  │ │ memory │ │  │    ──────────      │
│  │ │Password │ │  │ │Password│ │  │                    │
│  │ └─────────┘ │  │ └────────┘ │  │   Encrypted Zip    │
│  │             │  │ S A L T    ├─►│      Created       │
│  │             ├─►│    +       │  │                    │
└─►│  SHA3-384   │  │  Argon2    │  │     txt & hash     │
   │   H A S H   │  │  H A S H   │  │    files inside    │
   └─────────────┘  └────────────┘  └───────────────────┬┘
                                                        │
  ┌───────────────────────────────────────────────────┐ │
  │                                                   │ │
  │ Finished  Argon2  Hash  is  reprinted  on  screen │◄┘
  │                                                   │
  └───────────────────────────────────────────────────┘

```





## Explaining the choices within the script

```
############################################
###      Why did I pick those values?    ###
############################################
# Group - helps the user keep these passwords organized in their head. It's repeatable through multiple passwords.
# Age - random number data, but also, reminds the user to change their password yearly. If you try and hash 23 and it doesnt work, hash 22, and it does -- that reminds you to update the hash to this years age. 
# Service - Very important. This helps name all the files, is also used in the salt.
# Username - Should be different for each site. Also used for the salt.
#################################################
```


## In memory, never on disk

**Use a fifo (a named pipe), instead of writing to disk.** 

To do this, we'll be piping to stdin directly. 

The only gotcha is when the data is piped to fifo it needs to run in the background. We need this data to remain in memory for as long as the hashing takes -- before it can be encrypted.

Then just remove the file and it's gone from memory, never on disk.



### SHA3-384 --> Argon2

User values are hashed, so one-way-encryption, first using SHA3-384 and then using the Argon2 algorithm the second time. This is to ensure maximum bruteforce and dictionary attack protection.

SHA3-384 was chosen due to Argon2's input size.



### Argon2 input size

128 minus 1 characters are supported in command line utility for Argon2. *So this means we have to use something smaller than 512 bits.*

- SHA3-384's hash is 384 bits long. 

- This will give us a nice long hash to send to our key derivation function.

Just for reference, maximum input length for bcrypt is 72 characters.



## Argon2 settings


### A hash that works for our system

You need to make a hash value that works for your system. Are you on 256 cores with 2TB of ram? Or on a Raspbery Pi? 

Best way to set these values is to consider them as parameters affecting computational costs:

- `-p` to decide how many threads you can run without delaying other processes on the CPU

- `-k` or `-m` to set how much memory you can assign to the hashing set

- `-t` number of iterations, set this as high as the other two values will allow


#### Example hash values for argon2

* * *

Defaults for `argon2` are:
- Type:           Argon2i
- Parallelism:    1
- Memory:         4096 KiB
- Iterations:     3
- Hash length:    32

* * *

`Bitwarden` default parameters are:
`-p 4 -k 62500 -t 3`
- Parallelism:    4
- Memory:         64 MB
- Iterations:     3

* * *

These example parameters provided by [OWASP](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html#argon2id) are equivalent in the defense they provide. 
The only difference is a trade off between CPU and RAM usage.

```
    m=47104 (46 MiB), t=1, p=1 (Do not use with Argon2i)
    m=19456 (19 MiB), t=2, p=1 (Do not use with Argon2i)
    m=12288 (12 MiB), t=3, p=1
    m=9216 (9 MiB), t=4, p=1
    m=7168 (7 MiB), t=5, p=1
```

* * *

Example parameters for `this script` are:
`-id -p 4 -m 17 -t 13 -l 32`
- Type:           Argon2id
- Parallelism:    4
- Memory:         134.218 MB
- Iterations:     13
- Hash length:    32

The value chosen above, `-id -p 4 -m 17 -t 13 -l 32` is half the time of: `-id -p 4 -m 18 -t 11 -l 32`

You can use the latter if you need harder encryption.

* * *

#### Explaining Argon2 parameters in detail

##### Iteration count

You need to keep your `iterations` **higher than `10`** to keep entropy in the millions of years.

- `-t` > 10


##### Length of Hash

In this example, the last value on our parameters, we're using 32 bits. This creates a hash like MD5 or any other:

- `-l 32`


##### Memory used during the hash

kB and GB are like the metric system, but this software wants kibibytes. Directly under 1GB is 976562 kibibytes (a whole GB is 976562.5 kibibytes).  1 Gigabyte is equal to (10^9 / 2^10) kibibytes. You can specify this with: `-k 976562`

To specify memory in KiB use the `-m` flag. This uses 2^N KiB so, `-m 20` would be about one gigabyte (24576 bytes more), and `-m 18` is 268.44 MB.

* * *

`-id -p 64 -m 20 -t 256 -l 32`

The command above, would take my CPU **10 minutes** to generate!

* * *

`-id -p 8 -m 20 -t 16 -l 32`

These parameters are more reasonable, taking less than **1 minute**.

* * *

But, the maximum I want is, maybe, *3 seconds*.

So we'll use **13 iterations, 134mb of memory, and 4 threads**. 

The example parameters of `-p 4 -m 17 -t 13` took my CPU (Passmark score of 5500) *3.2 seconds* to generate.

* * *

#### Running an example argon2 hash

Let's make an argon2 hash and demonstrate how this can be used:

On the command line: 

```bash
echo pants | argon2 somefantasticsalt -id -p 4 -m 17 -t 13 -l 32
```

Will give you a lot of information printed on the screen, but the actual hash comes after the last dollar sign `$`.

You can use CyberChef to find this same value, if you're unable to install Argon2:

[https://gchq.github.io/CyberChef/#recipe=Argon2](https://gchq.github.io/CyberChef/#recipe=Argon2(%7B'option':'UTF8','string':'somefantasticsalt'%7D,13,131072,4,32,'Argon2id','Encoded%20hash')&input=cGFudHM)

You can also [combine operations in CyberChef](https://gchq.github.io/CyberChef/#recipe=SHA3('384')Argon2(%7B'option':'UTF8','string':'somefantasticsalt'%7D,13,131072,4,32,'Argon2id','Encoded%20hash')&input=cGFudHM) to re-create this password hash in your webbrowser:


For more information, I've included argon2's help below:

```
       -id             Use Argon2id instead of Argon2
       -t N            Sets the number of iterations to N (default = 3)
       -m N            Sets the memory usage of 2^N KiB (default 12)
       -k N            Sets the memory usage of N KiB (default 4096)
       -p N            Sets parallelism to N threads (default 1)
       -l N            Sets hash output length to N bytes (default 32)
       -e              Output only encoded hash
```

* * *

### Thanks! Good luck!
