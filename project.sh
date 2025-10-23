#!/bin/bash
# ===========================================
# File Organization Simulation in OS
# Modified to clearly show differences
# ===========================================

DISK_SIZE=50   # smaller disk so output fits on screen
for ((i=0; i<$DISK_SIZE; i++)); do
  DISK[$i]="."
done

METADATA="metadata.txt"
> $METADATA

# ----- Utility -----
show_disk() {
  echo "Disk Status:"
  for ((i=0; i<$DISK_SIZE; i++)); do
    echo -n "${DISK[$i]} "
    if (( ($i+1) % 10 == 0 )); then
      echo ""
    fi
  done
  echo ""
}

add_metadata() {
  echo "$1 $2 $3 $4" >> $METADATA
}

show_metadata() {
  echo "File Metadata:"
  cat $METADATA
  echo ""
}

# ----- Contiguous Allocation -----
create_file_contiguous() {
  local filename=$1
  local size=$2
  local found=0

  for ((i=0; i<=$DISK_SIZE-$size; i++)); do
    free=1
    for ((j=0; j<$size; j++)); do
      if [[ ${DISK[$((i+j))]} != "." ]]; then
        free=0
        break
      fi
    done

    if [[ $free -eq 1 ]]; then
      for ((j=0; j<$size; j++)); do
        DISK[$((i+j))]="$filename"
      done
      add_metadata "$filename" "$size" "contiguous" "$i-$((i+size-1))"
      echo "[Contiguous] File '$filename' created in continuous blocks $i-$((i+size-1))"
      found=1
      break
    fi
  done

  if [[ $found -eq 0 ]]; then
    echo "Error: Not enough contiguous space!"
  fi
}

# ----- Linked Allocation -----
create_file_linked() {
  local filename=$1
  local size=$2
  local allocated=0
  local blocks=()

  for ((i=0; i<$DISK_SIZE && allocated<$size; i++)); do
    if [[ ${DISK[$i]} == "." ]]; then
      DISK[$i]="$filename[L]"
      blocks+=($i)
      ((allocated++))
    fi
  done

  if [[ $allocated -eq $size ]]; then
    echo "[Linked] File '$filename' created with scattered blocks (linked): ${blocks[*]}"
    add_metadata "$filename" "$size" "linked" "${blocks[*]}"
  else
    echo "Error: Not enough free space!"
  fi
}

# ----- Indexed Allocation -----
create_file_indexed() {
  local filename=$1
  local size=$2
  local blocks=()
  local indexBlock=-1

  # Find index block
  for ((i=0; i<$DISK_SIZE; i++)); do
    if [[ ${DISK[$i]} == "." ]]; then
      indexBlock=$i
      DISK[$i]="$filename[I]"
      break
    fi
  done

  if [[ $indexBlock -eq -1 ]]; then
    echo "Error: No free block for index!"
    return
  fi

  allocated=0
  for ((i=0; i<$DISK_SIZE && allocated<$size; i++)); do
    if [[ ${DISK[$i]} == "." ]]; then
      DISK[$i]="$filename"
      blocks+=($i)
      ((allocated++))
    fi
  done

  if [[ $allocated -eq $size ]]; then
    echo "[Indexed] File '$filename' created with Index Block $indexBlock pointing to: ${blocks[*]}"
    add_metadata "$filename" "$size" "indexed" "$indexBlock -> ${blocks[*]}"
  else
    echo "Error: Not enough free space!"
  fi
}

# ----- Delete File -----
delete_file() {
  local filename=$1
  for ((i=0; i<$DISK_SIZE; i++)); do
    if [[ ${DISK[$i]} == "$filename" || ${DISK[$i]} == "$filename[L]" || ${DISK[$i]} == "$filename[I]" ]]; then
      DISK[$i]="."
    fi
  done
  grep -v "^$filename " $METADATA > temp && mv temp $METADATA
  echo "File '$filename' deleted."
}

# ----- Menu -----
while true; do
  echo "===== File Organization Simulator ====="
  echo "1. Show Disk"
  echo "2. Show Metadata"
  echo "3. Create File (Contiguous)"
  echo "4. Create File (Linked)"
  echo "5. Create File (Indexed)"
  echo "6. Delete File"
  echo "7. Exit"
  read -p "Enter choice: " choice

  case $choice in
    1) show_disk ;;
    2) show_metadata ;;
    3) read -p "Filename: " f; read -p "Size: " s; create_file_contiguous $f $s ;;
    4) read -p "Filename: " f; read -p "Size: " s; create_file_linked $f $s ;;
    5) read -p "Filename: " f; read -p "Size: " s; create_file_indexed $f $s ;;
    6) read -p "Filename: " f; delete_file $f ;;
    7) echo "Goodbye!"; exit ;;
    *) echo "Invalid choice!" ;;
  esac
done
