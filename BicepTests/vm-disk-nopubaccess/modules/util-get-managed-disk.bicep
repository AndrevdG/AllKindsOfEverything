param name string


resource disk 'Microsoft.Compute/disks@2022-03-02' existing = {
  name: name
}


output properties object = disk.properties
