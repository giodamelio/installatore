#!/usr/bin/env nu

use std 'log info'

# Declare dependencies in one place, so they can be overwritten by Nix
let sk_bin = "sk"
let bat_bin = "bat"
let disko_bin = "disko"
let templates_path = "templates"

# Check for runtime dependencies
let deps = [$sk_bin, $bat_bin, $disko_bin]
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


# Get info about drives
def drives [] {
  lsblk -o name,serial,size,uuid,path,type --json |
  from json |
  get blockdevices |
  where type == disk
}

# Select which drive you want to install on
def-env choose-drive [] {
  def format-drive [] {
    printf "%s\t%s\t%s" $in.path $in.size $in.serial
  }

  let driveCmd = (
    drives |
    each { ||
      $in |
      format-drive 
    } |
    to text |
    ^$sk_bin --delimiter "\t" --preview "lsblk -o name,size,ro,type,mountpoint,label,parttypename {1}" --preview-window up --header "Chose a drive to install on" --select-1 |
    complete
  )

  if $driveCmd.exit_code == 130 {
    return (error make {
      msg: "No drive chosen"
    })
  }

  let drive = (
    $driveCmd.stdout |
    split column "\t" path size serial
  )

  # Try to find a matching symlink by serial id
  let baseNamedSymlinks = (
    ls -l /dev/disk/by-id |
    each { || $in | update target ($in.target | path basename) }
  )
  let driveBaseName = ($drive.path | path basename | get 0)
  let matchingSymlinks = (
    $baseNamedSymlinks |
    where target == $driveBaseName |
    get name
  )
  if ($matchingSymlinks | length) > 0 {
    let newDiskName = (
      $matchingSymlinks |
      prepend ($drive.path | get 0) |
      to text |
      ^$sk_bin --header "Which name for the disk do you want to use?"
    )

    return $newDiskName
  }

  $drive | get 0 | get path
}

# Select partition layout you want
def-env choose-partitions [] {
  let templates = (ls $"($templates_path)/partitions" | get name | to text)
  let templateCmd = ($templates | ^$sk_bin --header "Choose partitions layout" --preview $"($bat_bin) {} --color=always" --preview-window up:80% --delimiter "/" --with-nth=-1 | complete)

  if $templateCmd.exit_code == 130 {
    return (error make {
      msg: "No partition template chosen"
    })
  }

  $templateCmd.stdout | str trim
}

# A barebones NixOS installer
def main [
  --root: path = "/mnt" # Root location to write configs to
] {
  try {
    # Choose a partition format
    let partitionLayout = (choose-partitions)
    printf "\nUsing partition layout %s\n" $partitionLayout

    # Choose drive to install on
    let drive = (choose-drive)
    printf "\nUsing drive %s\n" $drive

    # Create the partitions
    printf "%sAbout to partition %s\n" (ansi red_bold) $drive
    printf "This will destroy all data on the drive%s\n" (ansi reset)
    printf "Current partitions on disk:\n"
    lsblk -o name,ro,mountpoint,label,parttypename $drive
    let continue = (input "Continue [y/N]: ")
    if $continue != "y" {
      return (error make {
        msg: ""
      })
    }
    print "Formatting..."
    let $formatScript = (sudo $disko_bin --dry-run --root-mountpoint $root $partitionLayout --argstr disk $drive --mode zap_create_mount)
    sudo $formatScript
    print "Disk formatted and mounted"
  } catch {
    |e| printf "%sAborting. %s%s\n" (ansi red) $e.msg (ansi reset)
  }
}

# Print info on all the drives
def "main drives" [] {
  for drive in (drives) {
    print $drive.path
    $drive | reject children | print
    print $drive.children
  }
}
