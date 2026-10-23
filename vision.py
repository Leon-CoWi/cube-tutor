# vision.py - the camera part of CubeTutor
# What it does: takes 6 photos of your cube (one per face), reads the
# colour of every sticker, and writes the answer into cube.txt.
#   python vision.py capture   -> take the 6 photos
#   python vision.py read      -> read the photos and write cube.txt
import os
import sys
from collections import Counter

import cv2
import numpy as np
from scipy.optimize import linear_sum_assignment

# The folder this file is in. Photos and cube.txt are saved here too.
FOLDER = os.path.dirname(os.path.abspath(__file__))
# The order of the 54 letters in cube.txt: u is 1-9, r is 10-18, and so on.
FACE_ORDER = "urfdlb"

# The 6 photos to take, in order:
# (face letter, centre colour toward the camera, centre colour on top)
SCREENS = [
    ("f", "GREEN",  "YELLOW"),
    ("r", "ORANGE", "YELLOW"),
    ("b", "BLUE",   "YELLOW"),
    ("l", "RED",    "YELLOW"),
    ("u", "YELLOW", "BLUE"),
    ("d", "WHITE",  "GREEN"),
]


def photo_path(face):
    return os.path.join(FOLDER, "face_" + face + ".png")


def grid_geometry(h, w):
    """Where the 3x3 grid sits: left, top, and the size of one square.
    The same numbers are used to draw the grid AND to read the colours."""
    side = min(h, w) * 55 // 100
    return (w - side) // 2, (h - side) // 2, side // 3


# ---------- Part 1: take the photos ----------

def draw_grid(frame, text):
    """Gives back a copy of the camera picture with the 3x3 grid and the
    instruction text drawn on it."""
    shown = frame.copy()
    h, w = shown.shape[:2]
    x0, y0, cell = grid_geometry(h, w)
    for i in range(4):
        cv2.line(shown, (x0 + i * cell, y0), (x0 + i * cell, y0 + 3 * cell), (0, 255, 0), 2)
        cv2.line(shown, (x0, y0 + i * cell), (x0 + 3 * cell, y0 + i * cell), (0, 255, 0), 2)
    cv2.putText(shown, text, (10, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.7, (0, 255, 0), 2)
    cv2.putText(shown, "SPACE = take photo   ESC = quit", (10, h - 15),
                cv2.FONT_HERSHEY_SIMPLEX, 0.6, (255, 255, 255), 2)
    return shown


def capture():
    cam = cv2.VideoCapture(0, cv2.CAP_DSHOW)      # DSHOW works best on Windows
    if not cam.isOpened():
        print("Could not open the camera.")
        return False
    n = 0
    while n < len(SCREENS):
        face, toward, top = SCREENS[n]
        text = "%d/6: %s centre toward camera, %s centre on top" % (n + 1, toward, top)
        ok, frame = cam.read()
        if not ok:
            print("The camera gave no picture.")
            break
        cv2.imshow("CubeTutor", draw_grid(frame, text))
        key = cv2.waitKey(30) & 0xFF
        if key == 27:                              # ESC: stop
            break
        if key == 32:                              # SPACE: save the photo
            cv2.imwrite(photo_path(face), frame)
            print("saved", photo_path(face))
            n += 1
    cam.release()
    cv2.destroyAllWindows()
    return n == len(SCREENS)


# ---------- Part 2: read the colours ----------

def sample_face(img):
    """Gives the colour of the 9 stickers of one photo, row by row.
    (Colours are in Lab, a colour format that is better for comparing.)"""
    h, w = img.shape[:2]
    x0, y0, cell = grid_geometry(h, w)
    labs = []
    for row in range(3):
        for col in range(3):
            cx = x0 + col * cell + cell // 2
            cy = y0 + row * cell + cell // 2
            # take a small patch in the middle of the sticker, and use its middle value
            patch = img[cy - 10:cy + 11, cx - 10:cx + 11].reshape(-1, 3)
            bgr = np.median(patch, axis=0).astype(np.uint8)
            lab = cv2.cvtColor(bgr.reshape(1, 1, 3), cv2.COLOR_BGR2LAB)
            labs.append(lab.reshape(3).astype(float))
    return labs


def distance(a, b):
    """How different two colours are. Brightness (the first number) counts
    much less than the actual colour, because light and glare change it a lot."""
    return (0.25 * (a[0] - b[0])) ** 2 + (a[1] - b[1]) ** 2 + (a[2] - b[2]) ** 2


def read_letters():
    """Gives back (the 54 letters, the stickers that were a close call).
    If a photo is missing, gives back (None, None)."""
    samples = {}
    for face in FACE_ORDER:
        img = cv2.imread(photo_path(face))
        if img is None:
            print("Missing photo:", photo_path(face))
            return None, None
        samples[face] = sample_face(img)
    # The 48 stickers that are not centres. Each colour has exactly 8 of them.
    stickers = [(face, i) for face in FACE_ORDER for i in range(9) if i != 4]
    labs = [samples[face][i] for face, i in stickers]
    # Reference colours = the centre stickers (a centre never moves, so we know
    # its colour). The white centre has a logo, so for white we use the
    # 9 stickers with the least colour (the greyest ones) instead.
    refs = {face: samples[face][4] for face in FACE_ORDER}
    grey = sorted(labs, key=lambda lab: (lab[1] - 128) ** 2 + (lab[2] - 128) ** 2)[:9]
    refs["d"] = np.mean(grey, axis=0)
    owner = None
    for _ in range(5):          # decide the colours, then improve the references, 5 times
        cost = np.array([[distance(lab, refs[colour])
                          for colour in FACE_ORDER for _ in range(8)]
                         for lab in labs])
        # give every sticker a colour, but exactly 8 stickers per colour
        rows, cols = linear_sum_assignment(cost)
        owner = [None] * len(labs)
        for r, c in zip(rows, cols):
            owner[r] = FACE_ORDER[c // 8]
        for colour in FACE_ORDER:
            mine = [labs[k] for k in range(len(labs)) if owner[k] == colour]
            if colour != "d":
                mine.append(samples[colour][4])        # add its centre (no logo)
            refs[colour] = np.mean(mine, axis=0)
    letters = []
    close = []
    k = 0
    for face in FACE_ORDER:
        for i in range(9):
            if i == 4:
                letters.append(face)                   # a centre is always its own face
            else:
                letters.append(owner[k])
                # if another colour looks closer, it is a close call: warn the user
                nearest = min(FACE_ORDER, key=lambda c: distance(labs[k], refs[c]))
                if nearest != owner[k]:
                    close.append("face %s, row %d, column %d" % (face, i // 3 + 1, i % 3 + 1))
                k += 1
    return "".join(letters), close


def show_letters(letters):
    for i, face in enumerate(FACE_ORDER):
        chunk = letters[9 * i:9 * i + 9]
        print("face", face)
        for r in range(3):
            print("  ", " ".join(chunk[3 * r:3 * r + 3]))


def read_cube():
    letters, close = read_letters()
    if letters is None:
        return False
    show_letters(letters)
    for place in close:
        print("Close call (please check by eye):", place)
    # a real cube has exactly 9 stickers of each colour
    counts = Counter(letters)
    bad = [f for f in FACE_ORDER if counts[f] != 9]
    if bad:
        print("Colour counts are wrong (need 9 of each):", dict(counts))
        print("Retake the photos with better light; nothing was written.")
        return False
    with open(os.path.join(FOLDER, "cube.txt"), "w") as f:
        f.write(letters + "\n")
    print("Wrote cube.txt:", letters)
    return True


if __name__ == "__main__":
    command = sys.argv[1] if len(sys.argv) > 1 else ""
    if command == "capture":
        print("done" if capture() else "stopped before all six photos")
    elif command == "read":
        read_cube()
    else:
        print("Use: python vision.py capture   or   python vision.py read")