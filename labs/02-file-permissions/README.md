# Lab 02 - Linux File Permissions and Ownership

## Objective

Practice Linux file permissions, ownership management, and access control using two local users: sysadmin and developer1.

## Environment

- Ubuntu Server 24.04 LTS
- Oracle VirtualBox
- Users: sysadmin, developer1

## Permission Management

Created two test files and a shared directory.

| Resource | Permissions | Purpose |
|----------|-------------|---------|
| private.txt | 600 | Owner-only access |
| public.txt | 644 | Public read access |
| shared/ | 750 | Restricted directory access |

## Access Control Testing

Tested file access using developer1.

- Reading private.txt was denied.
- Reading public.txt succeeded.
- Listing shared/ was denied.

## Ownership Management

Changed ownership of private.txt from sysadmin to developer1.

After the ownership change, developer1 successfully read the file.

Changed group ownership using chgrp.

Restored original ownership to sysadmin:sysadmin.

## Commands Used

- chmod
- chown
- chgrp
- ls -l
- sudo -u
- id
- groups

## Key Takeaways

Linux permissions control access to files and directories.

chmod modifies permissions, while chown and chgrp manage ownership.

Proper permissions help protect sensitive server resources.
