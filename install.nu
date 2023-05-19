#!/usr/bin/env nu

use std 'log info'

# Declare dependencies in one place, so they can be overwritten by Nix
let sk_bin = "sk"

# Check for runtime dependencies
let deps = [$sk_bin]
let missing = (
  $deps |
  each { || [$in, (which $in)] } |
  filter { |dep| ($dep | get 1 | length) == 0 } |
  each { || $in | get 0 }
)
if ($missing | length) > 0 {
  print "Error missing dependencies:"
  $missing | each { || printf "  %s\n" $in }
  exit 1
}

# Get info from disks
let drives = (
  lsblk -o name,serial,size,uuid,path,type --json |
  from json |
  get blockdevices |
  where type == disk
)

# Select which drive you want to install on
def choose-drive [] {
  def format-drive [] {
    printf "%s\t%s\t%s" $in.path $in.size $in.serial
  }

  let drive = (
    $drives |
    each { ||
      $in |
      format-drive 
    } |
    to text |
    ^$sk_bin --delimiter "\t" --preview "lsblk -o name,size,ro,type,mountpoint,label,parttypename {1}" --preview-window up --header "Chose a drive to install on" --select-1 |
    split column "\t" path size serial |
    get 0
  )

  $drive
}

let drive = (choose-drive)
printf "Using drive %s\n" $drive.path
print $drive
