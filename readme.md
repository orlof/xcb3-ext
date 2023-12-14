# XCB3-GFX: Low Level Graphic Primitives Library

**XCB3-GFX Library Summary**:

- **Purpose**: The XCB3-GFX library is tailored for drawing on C64 bitmaps, offering developers an array of graphic primitives.

- **Compatibility**: The library supports both hires and multicolor bitmap modes. Some of the subroutines have two variants - one for Hires and another for Multicolor. Those subroutines are easy to recognize as their multicolor variant ends with MC e.g. Text() for hires and TextMC() for multicolor.

- **Flexibility**: XCB3-GFX can operate with any of the VIC banks (0-3). Unlike some other libraries, there's no "hard-coded" memory location for the bitmap, screen, or font, which provides developers with a high degree of flexibility. XCB3-GFX drawing primitives work even if target memory is located in bank 3 "behind" io and kernel.

- **Performance**: XCB3-GFX is not the fastest library, but it ain't slow either. It can plot random hires lines at a rate of approximately 12000 pixels per second, or around 85 cycles per pixel. 8 lines "mystify" updates about 8 times per second in multicolor mode. Philosophy of this library is to try balancing performance, memory consumption and usability. In VERY rough terms memory consumption is about 3k for hires routines and 3k for multicolor routines. If all features are in use then memory consumption is about 6k. Current release contains self modifying code that makes it unsuitable for ROM.

- **Usage**: For the sake of maintaining a decent performance, there's no built-in sanity check for the input arguments. As a result, if users input values that instruct drawings outside of the screen boundaries, the library's behavior becomes undefined, and it won't provide warnings or errors.

- **API**: The library API is intentionally designed with a single-task focus for each subroutine. API calls are specifically tailored to either manipulate bitmap graphics (drawing operations) or manage display colors (Screen memory or Color RAM).

- **Color Palette**: This library is designed to have constant color palette in the whole screen. I.e. in multicolor operations you have only the 4 color palette defined with  `FillColorsMC(c0, c1, c2, c3)`. This limitation is for performance reasons but also because VIC supports separate colors only in 8x8 (or 4x8) cells and exact coloring is anyway impossible.

- **Impact on XC-Basic Keywords:** Changing the screen memory or bank address within your program can disrupt XC-Basic keywords and commands that depend on those memory locations. Examples of such commands include Sprite Shape, Print, and others. When altering these settings in your code, it's important to consider the potential impact on XC-Basic's functionality.

  To address this issue, you can follow these steps:
  1. Set the desired video bank using `CALL SetVideoBank(...)`
  2. Set the screen memory location with `CALL SetScreenMemory(...)`
  3. Call XC-Basic's `Screen` command to update its internal configuration.

  However, keep in mind that the XC-Basic `Screen` command can be slow and may introduce delays in your program. Therefore, it is not recommended for use in time-critical scenarios, especially when working with double buffering or other performance-sensitive operations.

- **Interrupt Protection and Bank 3:** Every routine that manipulates bitmap or screen memory in the library is protected by disabling interrupts. This protection is necessary to bank out the kernel and I/O for reading these memory locations. While some routines, like `Plot`, disable interrupts for a short duration (around 100 cycles), others, such as `FillBitmap`, may disable them for an extended period (about 33,000 cycles). Consequently, raster interrupts are not compatible with Bank 3. By default, interrupts are disabled even if you are not using Bank 3 ($C000-$FFFF). However, if you do not intend to use Bank 3, you can disable this protection using the following code in your main program:

  ```assembly
  ASM
      LIB_GFX_DISABLE_BANK_3
  END ASM
  ```

  After executing this command, only routines that require access to ROM fonts will disable interrupts. In summary, if you need to use interrupts, it's advisable to disable Bank 3 and avoid using it for bitmap graphics to ensure compatibility and smooth operation.

### Example

```basic
INCLUDE "lib_gfx.bas"

CONST TRUE = $ff
CONST FALSE = 0

CALL SetVideoBank(3)
CALL SetBitmapMemory(1)
CALL SetScreenMemory(0)
CALL SetGraphicsMode(STANDARD_BITMAP_MODE)
CALL FillBitmap(0)
CALL FillColors(COLOR_RED, COLOR_WHITE)

CALL Plot(160, 50, MODE_SET)

CALL Circle(160, 100, 90, MODE_SET, MODE_TRANSPARENT)

CALL Draw(0, 0, 319, 199, MODE_SET)
CALL Draw(0, 199, 319, 0, MODE_SET)

CALL Text(9, 2, MODE_SET, MODE_TRANSPARENT, TRUE, "Hello World", ROM_CHARSET_LOWERCASE)
```

#### Line Explanation:

- `INCLUDE "lib_gfx.bas"`:
  This line imports the graphics library "lib_gfx.bas". This library contains all the subroutines and functions required for graphical operations.

- `CALL SetVideoBank(3)`:
  This sets the VIC bank to Bank #3 (address range: $C000-$FFFF, 49152-65535).

- `CALL SetBitmapMemory(1)`:
  This sets the bitmap memory to the location $2000-$3F3F in current bank (absolute address range: $E000-$FF3F).

- `CALL SetScreenMemory(0)`:
  This sets the screen memory to the location $0000-$03FF in the current VIC bank (address range: $C000-$C3ff).

- `CALL SetGraphicsMode(STANDARD_BITMAP_MODE)`:
  Activates the standard bitmap mode. In this mode, the screen displays a high-resolution 320x200 pixels bitmap.

- `CALL FillBitmap(0)`:
  This fills the entire bitmap with the value 0 (clearing all pixels).

- `CALL FillColors(COLOR_RED, COLOR_WHITE)`:
  This sets the screen memory with a value derived from a combination of the white and red colors. This combination sets the foreground color to white and the background color to red.

## API Documentation

Below is the detailed documentation for each subroutine provided by the XCB3-GFX library.

### Table of Contents:

#### Memory
- [SetVideoBank](#setvideobank)
- [SetGraphicsMode](#setgraphicsmode)
- [SetScreenMemory](#setscreenmemory)
- [SetCharacterMemory](#setcharactermemory)
- [SetBitmapMemory](#setbitmapmemory)
- [ResetScreen](#resetscreen)
- [ScreenOn](#screenon)
- [ScreenOff](#screenoff)

#### Double Buffering
- [DoubleBufferOn](#doublebufferon)
- [DoubleBufferOff](#doublebufferoff)
- [BufferSwap](#bufferswap)

#### Color
- [FillColors](#fillcolors)
- [FillColorsMC](#fillcolorsmc)
- [FillBitmap](#FillBitmap)
- [FillScreenMemory](#fillscreenmemory)
- [FillColorMemory](#fillcolormemory)
- [SetColorInRect](#setcolor)

#### Drawing
- [GetPixel](#getpixel)
- [GetPixelMC](#getpixelmc)
- [Plot](#plot)
- [PlotMC](#plotmc)
- [Draw](#draw)
- [DrawMC](#drawmc)
- [HDraw](#hdraw)
- [HDrawMC](#hdrawmc)
- [VDraw](#vdraw)
- [VDrawMC](#vdrawmc)
- [Circle](#circle)
- [CircleMC](#circlemc)
- [Rect](#rect)
- [RectMC](#rectmc)

#### Text
- [CopyCharROM](#copycharrom)
- [TextMC](#textmc)
- [Text](#text)
- [PetsciiToScreenCode](#petsciitoscreencode)

---

### SetVideoBank
#### SetVideoBank(BankNumber AS BYTE)
This subroutine sets the VIC bank for graphic operations. The Commodore 64 has four possible video banks, and you can choose between them by passing the appropriate bank number.

**Parameters:**
- **BankNumber**: A byte representing the desired video bank. It can take values between 0 and 3, inclusive.

  - **Bank #0**:
    - Memory Range: `$0000-$3FFF`
    - Decimal Range: `0-16383`

  - **Bank #1**:
    - Memory Range: `$4000-$7FFF`
    - Decimal Range: `16384-32767`

  - **Bank #2**:
    - Memory Range: `$8000-$BFFF`
    - Decimal Range: `32768-49151`

  - **Bank #3**:
    - Memory Range: `$C000-$FFFF`
    - Decimal Range: `49152-65535`

**Usage:**
```basic
SetVideoBank(2)  ' This will set the video bank to Bank #2
```

**Note**: This is a slow operation as it also updates y coordinate tables and fast clear routines.

[Back to TOC](#table-of-contents)

---

### SetGraphicsMode
#### SetGraphicsMode(Mode AS BYTE)

This subroutine sets the desired graphics mode for display operations on the Commodore 64. Different modes enable different visual capabilities and styles.

**Parameters:**
- **Mode**: A byte representing the graphics mode. It must be one of the following constants:

  - **STANDARD_CHARACTER_MODE**:
    - **Description**: A mode primarily used for 40x25 text display. It allows for a single foreground color for each character against a common background.

  - **MULTICOLOR_CHARACTER_MODE**:
    - **Description**: Variation of the standard character mode. It allows three unique colors per character plus a common background but halves the horizontal resolution.

  - **STANDARD_BITMAP_MODE**:
    - **Description**: A high-resolution mode that enables 320x200 pixel-by-pixel graphics. In this mode, each 8x8 pixel cell can have a unique foreground and background color.

  - **MULTICOLOR_BITMAP_MODE**:
    - **Description**: A 160x200 multicolor version of the bitmap mode. It reduces the resolution but allows for up to three colors per 8x8 pixel cell plus a common background, giving more color-rich graphics.

  - **EXTENDED_BACKGROUND_COLOR_MODE**:
    - **Description**: This mode extends the standard character mode by offering additional background colors. While the foreground remains singular per character, there are now four possible background colors to choose from.

  - **INVALID_MODE**:
    - **Description**: ScreenOn and ScreenOff routines switch the DEN-bit ($d011 bit #4 Display ENable-bit) that is updated only once per frame. To turn screen off in mid-frame you can use illegal graphics mode. Technically INVALID_MODE sets the bitmap mode and the extended color mode on simultaneously. This is not a valid graphics mode in VIC and it will draw the whole background area black.

**Usage:**
```basic
SetGraphicsMode(STANDARD_BITMAP_MODE)  ' This will set the graphics mode to STANDARD_BITMAP_MODE
```

**Note**: Switching between modes will drastically alter the appearance of any existing screen content. Ensure that the desired mode is set before performing any drawing or display operations to achieve consistent visual results.

[Back to TOC](#table-of-contents)

---

### SetScreenMemory
#### SetScreenMemory(Ptr AS BYTE)

This subroutine sets the starting location for screen memory. The location depends on the selected graphics mode:

- **In Text Modes**: Screen memory holds the character codes for each of the characters displayed in the 40x25 screen grid, which utilizes 1KB of memory.

- **In Bitmap Modes**: Screen memory holds the color data for each 8x8 pixel cell (or 4x8 pixel cell when in multicolor mode).

**Parameters:**
- **Ptr**: A byte indicating the relative position within the selected VIC bank. Here are the possible values:

| Ptr Value | Memory Range  | Decimal Range  |
|-----------|---------------|----------------|
| 0         | `$0000-$03FF` | `0-1023`       |
| 1         | `$0400-$07FF` | `1024-2047`    |
| 2         | `$0800-$0BFF` | `2048-3071`    |
| 3         | `$0C00-$0FFF` | `3072-4095`    |
| 4         | `$1000-$13FF` | `4096-5119`    |
| 5         | `$1400-$17FF` | `5120-6143`    |
| 6         | `$1800-$1BFF` | `6144-7167`    |
| 7         | `$1C00-$1FFF` | `7168-8191`    |
| 8         | `$2000-$23FF` | `8192-9215`    |
| 9         | `$2400-$27FF` | `9216-10239`   |
| 10        | `$2800-$2BFF` | `10240-11263`  |
| 11        | `$2C00-$2FFF` | `11264-12287`  |
| 12        | `$3000-$33FF` | `12288-13311`  |
| 13        | `$3400-$37FF` | `13312-14335`  |
| 14        | `$3800-$3BFF` | `14336-15359`  |
| 15        | `$3C00-$3FFF` | `15360-16383`  |

**Usage:**
```basic
SetScreenMemory(5)  ' This will set the screen memory starting location to `$1400-$17FF`
```

**Note**: This is a slow operation as it also updates y coordinate tables.

**Note**: Changing the screen memory location during active display operations might produce unexpected visual results. It's advisable to set the screen memory location during initialization or when the screen is not actively being updated.

[Back to TOC](#table-of-contents)

---

### SetCharacterMemory
#### SetCharacterMemory(Ptr AS BYTE)

This subroutine specifies the memory location for the 2k character set. The character set determines the design of the characters used on the screen in text modes, including custom fonts if you've created or loaded any.

Note that this character memory pointer is not anyway related to the CharSet address that you can give for
Text(...) subroutine.

**Parameters:**
- **Ptr**: A byte indicating the relative position within the selected VIC bank for the character memory. Here are the possible values:

| Ptr Value | Memory Range  | Decimal Range  |
|-----------|---------------|----------------|
| 0         | `$0000-$07FF` | `0-2047`       |
| 1         | `$0800-$0FFF` | `2048-4095`    |
| 2         | `$1000-$17FF` | `4096-6143`    |
| 3         | `$1800-$1FFF` | `6144-8191`    |
| 4         | `$2000-$27FF` | `8192-10239`   |
| 5         | `$2800-$2FFF` | `10240-12287`  |
| 6         | `$3000-$37FF` | `12288-14335`  |
| 7         | `$3800-$3FFF` | `14336-16383`  |

**Usage:**
```basic
SetCharacterMemory(4)  ' This will set the character memory location to `$2000-$27FF`
```

**Note**: Modifying the character memory location while displaying text can yield unpredictable visual outputs. For optimal results, set the character memory location during system initialization or during periods when text display is not being actively modified.

[Back to TOC](#table-of-contents)

---

### SetBitmapMemory
#### SetBitmapMemory(Ptr AS BYTE)

This subroutine specifies the memory location for the bitmap graphics. The bitmap memory holds the pixel data used for detailed graphics in bitmap modes, allowing for intricate designs, images, and more.

**Parameters:**
- **Ptr**: A byte indicating the relative position within the selected VIC bank for the bitmap memory. Here are the possible values:

| Ptr Value | Memory Range  | Decimal Range   |
|-----------|---------------|-----------------|
| 0         | `$0000-$1FFF` | `0-8191`        |
| 1         | `$2000-$3FFF` | `8192-16383`    |

**Usage:**
```basic
SetBitmapMemory(1)  ' This will set the bitmap memory location to `$2000-$3FFF`
```

**Note**: This is a slow operation as it also updates y coordinate tables and fast clear routines.

**Note**: Modifying the bitmap memory location while displaying graphics can yield unpredictable visual outputs. For the best results, it's recommended to set the bitmap memory location during system initialization or during periods when the graphical display is not being actively updated.

### ResetScreen()

This subroutine returns the VIC's configuration to a default state for basic text display, providing a convenient way to ensure a known state for the screen display system.

**Actions Performed:**
1. Sets the VIC bank to `Bank 0` (`$0000-$3FFF`, `0-16383`).
2. Sets the screen memory location to `$0400-$07FF` (`1024-2047`).
3. Sets the character memory location to `$1000-$17FF` (`4096-6143`).
4. Enables `Standard Character Mode` for basic text display without any graphics modes or custom character sets.

**Usage:**
```basic
ResetScreen()  ' This will restore the default VIC configurations as outlined above.
```

**Note**: Using `ResetScreen()` is helpful when transitioning from graphics or custom modes back to a standard text environment. It ensures predictable behavior by reverting to the familiar settings of the C64's default text mode. Always ensure any ongoing screen updates or animations are halted before resetting to avoid visual glitches or undesirable behaviors.

[Back to TOC](#table-of-contents)

---

### ScreenOn()
#### ScreenOn()

The `ScreenOn()` subroutine reactivates the screen display after it has been turned off, restoring the visibility of the content on the screen. While the screen provides a visual interface, it also utilizes a substantial number of CPU cycles for refreshing and maintenance. Reactivating the screen with `ScreenOn()` will mean that these cycles are once again dedicated to screen updates.

### **Details:**

- **Effect on Screen:** The previously obscured screen content becomes visible again, with the display resuming its normal state.

- **CPU Cycle Impact:** In total, 19,705 CPU cycles are available per frame. With the screen on, the VIC (Video Interface Chip) will "steal" between 960 to 1,550 cycles per frame for screen updates, reducing the cycles available to the CPU for other operations.

### **Usage**

```basic
ScreenOn()  ' This restore the normal screen contents visible
```

- Use this subroutine to restore the display after performing computations with the screen off using the `ScreenOff()` subroutine.
- Always ensure that the screen is turned back on after turning it off, especially before expecting any visual feedback or results on the screen.
- There is no need to sync this operation to vertical blank as screen on/off is refreshed only between frames

[Back to TOC](#table-of-contents)

---

### ScreenOff()
#### ScreenOff()

The `ScreenOff()` subroutine turns off the screen display, resulting in the complete screen being covered by the border. When the screen is active, the VIC (Video Interface Chip) utilizes a significant number of CPU cycles to refresh and maintain the display. Turning the screen off with `ScreenOff()` ensures that these cycles are reclaimed, providing the CPU with more processing time per frame.

### **Details:**

- **Effect on Screen:** The entire visible screen area is obscured, and only the border remains visible.

- **CPU Cycle Impact:** Under normal conditions, there are 19,705 CPU cycles available per frame. However, when the screen is on, the VIC "steals" between 960 to 1,550 cycles per frame for screen updating. This reduces the available CPU cycles. Using `ScreenOff()` ensures that these cycles are not lost to screen updates.

### **Usage**

**Usage:**
```basic
ScreenOff()  ' This will cover the whole screen with border
```

- It might be beneficial to use this subroutine during intense computational operations where every CPU cycle counts.
- Remember to turn the screen back on, using a counterpart subroutine (if available), to display graphics or text after processing.
- There is no need to sync this operation to vertical blank as screen on/off is refreshed only between frames

[Back to TOC](#table-of-contents)

---

### DoubleBufferOn
#### DoubleBufferOn()

The `DoubleBufferOn()` subroutine activates double buffering, a technique used to eliminate flickering in screen displays. Flickering often occurs when rapidly changing or updating graphics on the screen, resulting in an undesirable visual effect. Double buffering solves this problem by maintaining two screen buffers: one visible to the user and one hidden for drawing operations. This approach enhances the visual experience in applications like games and multimedia by displaying one frame while buffering drawing operations to the other.

### **Details:**

- **Flicker Elimination:** The primary purpose of enabling double buffering is to eliminate flickering on the screen during rapid updates or animations. It achieves this by displaying one complete frame while preparing the next one in the hidden buffer.

- **Buffer Assignment:** When double buffering is active, all future calls to change memory configurations (such as setting screen, character, or bitmap memory) will affect the hidden buffer. Similarly, all drawing operations will be routed to the hidden buffer.

- **Buffer Swap:** To update the screen, users can call the `BufferSwap()` subroutine, which swaps the visible and hidden buffers. This operation ensures that the new frame is displayed to the user while the next frame is being prepared in the previously visible buffer.

- **Sync Responsibility:** It's essential to note that the library does not automatically perform any screen copying or clearing between the buffers. Users are responsible for managing and synchronizing the content between the visible and hidden buffers to maintain a seamless display.

- **Memory Consumption:** Utilizing double buffering effectively doubles the memory consumption, as both a visible and a hidden buffer must be maintained. For example, if your application originally used 9k of memory, enabling double buffering will increase it to 18k.

### **Usage Notes:**

- Use `DoubleBufferOn()` when working with applications that involve rapid screen updates or animations to achieve smoother, flicker-free visuals.
- Refer to the provided example `demo3.bas` in the repository to see the practical implementation and benefits of double buffering.

---

[Back to TOC](#table-of-contents)

---

### DoubleBufferOff
#### DoubleBufferOff()

The `DoubleBufferOff()` subroutine deactivates double buffering, which is a technique used to eliminate screen flickering during rapid screen updates. Double buffering involves maintaining two screen buffers: one visible to the user and one hidden for drawing operations. Disabling double buffering with `DoubleBufferOff()` will revert to the standard screen display mode without the benefits of flicker elimination.

### **Details:**

- **Flicker Reintroduction:** When double buffering is turned off, screen updates may lead to flickering, particularly during rapid or dynamic changes to the screen content.

- **Buffer Assignment:** Without double buffering, all memory configuration changes (e.g., setting screen, character, or bitmap memory) and drawing operations directly affect the visible screen buffer.

- **Memory Consumption:** Disabling double buffering reduces memory consumption to its standard level. While enabled, double buffering effectively doubles memory usage due to the need to maintain both a visible and a hidden buffer.

### **Usage Notes:**

- Use `DoubleBufferOff()` when you no longer require flicker-free screen updates or when memory constraints are a concern.

- Be aware that disabling double buffering may reintroduce screen flickering, particularly when performing rapid screen updates or animations.

---

The `DoubleBufferOff()` subroutine serves as the counterpart to `DoubleBufferOn()`, allowing users to revert to the standard screen display mode when flicker elimination is not required.

[Back to TOC](#table-of-contents)

---

### BufferSwap
#### BufferSwap()

The `BufferSwap()` subroutine is used in conjunction with double buffering to exchange the visible and hidden screen buffers. Double buffering is a technique employed to eliminate screen flickering during rapid screen updates. It maintains two screen buffers: one visible to the user and one hidden for drawing operations. `BufferSwap()` facilitates switching between these buffers, allowing the hidden buffer to become the visible buffer, and vice versa.

### **Details:**

- **Buffer Exchange:** When `BufferSwap()` is called, the contents of the hidden buffer become visible to the user, and the previous visible buffer becomes the new hidden buffer.

- **Flicker Elimination:** This swapping process ensures that screen updates occur smoothly and without flickering, as the new frame is displayed only once it's fully prepared in the hidden buffer.

- **Usage with Double Buffering:** `BufferSwap()` is typically used in conjunction with double buffering, where one buffer is being drawn to while the other is being displayed. The routine is called after drawing operations are completed in the hidden buffer.

- **Synchronization Responsibility:** It's important to note that `BufferSwap()` does not automatically synchronize or clear the content between the visible and hidden buffers. Users are responsible for managing and ensuring that the content in both buffers is consistent. Typically hidden buffer is cleared with `FillBitmap(0)` after swap.

### **Usage Notes:**

- Use `BufferSwap()` when working with double buffering to switch between the visible and hidden screen buffers.

- Always call `BufferSwap()` after completing drawing operations in the hidden buffer to display the updated frame without flickering.

---

The `BufferSwap()` subroutine is an essential component of double buffering and ensures that the transition between the visible and hidden buffers is smooth and flicker-free during screen updates.
[Back to TOC](#table-of-contents)

---

### FillBitmap
#### FillBitmap(Value AS BYTE)

This subroutine provides an efficient way to fill the entire bitmap memory with a specified byte value. This is useful for quickly setting up a blank canvas or a consistent patterned background in both hires and multicolor bitmap modes.

**Parameters:**
- **Value**: The byte value to be filled into the entire bitmap memory. Depending on the bitmap mode (hires or multicolor), the interpretation of this byte will change. In hires mode, each bit of the byte corresponds to a pixel, while in multicolor mode, two bits together will define the color of a pixel.

**Usage:**
```basic
FillBitmap(0x00)  ' This will clear the entire bitmap to black (or the respective background color).
```

**Note**: Core loops of this subroutine completes in 33364 clock cycles. It takes about 2 frames to fill the 8k buffer.

**Note**: This subroutine only writes to the bitmap memory. If you wish to modify the screen memory or color RAM, you will need to utilize separate subroutines: `FillScreenMemory(..)` for screen memory and `FillColorMemory(...)` for color RAM. Ensure the respective areas are updated correctly to achieve the desired visual outcome.

[Back to TOC](#table-of-contents)

---

### FillColors
#### FillColors(Color0 AS BYTE, Color1 AS BYTE)

Select colors from C64's 16 color palette to current hires screen's 2 color palette.

**Parameters:**
- **Color0**: The color value for the entire display that denotes the Color 0 for each 8x8 pixel cell (paper color).
- **Color1**: The color value for the entire display that denotes the Color 1 for each 8x8 pixel cell (ink color).

**Usage:**
```basic
FillColors(COLOR_WHITE, COLOR_BLACK)  ' This will fill make Color0 (paper) in the entire screen to appear white and color1 (ink) black.
```

[Back to TOC](#table-of-contents)

---

### FillColorsMC
#### FillColorsMC(Color0 AS BYTE, Color1 AS BYTE, Color2 AS BYTE, Color3 AS BYTE)

Select colors from C64's 16 color palette to current multicolor screen's 4 color palette.

**Parameters:**
- **Color0**: The color value for the entire display that denotes the Color 0 for each 4x8 pixel cell.
- **Color1**: The color value for the entire display that denotes the Color 1 for each 4x8 pixel cell.
- **Color2**: The color value for the entire display that denotes the Color 2 for each 4x8 pixel cell.
- **Color3**: The color value for the entire display that denotes the Color 3 for each 4x8 pixel cell.

**Usage:**
```basic
FillColorsMC(COLOR_BLACK, COLOR_WHITE, COLOR_BLUE, COLOR_RED);
```

[Back to TOC](#table-of-contents)

---

### FillScreenMemory
#### FillScreenMemory(Value AS BYTE)

This subroutine offers a straightforward way to populate the entire screen memory with a specified byte value. Screen memory holds character codes or color data depending on the mode, which directly influences how the screen appears.

**Parameters:**

**Usage:**
```basic
FillScreenMemory(0x20)  ' This will fill the screen memory with spaces (assuming standard character mode).
```

**Note**: This subroutine solely modifies the screen memory. If you intend to adjust the bitmap graphics or color RAM, you must employ other relevant subroutines like `FillBitmap(..)` for bitmap memory and `FillColorMemory(...)` for color RAM. It's essential to coordinate updates across these memories to attain the desired visual representation.

[Back to TOC](#table-of-contents)

---

### FillColorMemory
#### FillColorMemory(Value AS BYTE)

This subroutine provides a method to uniformly set all the values in the color RAM with a specified byte value. The color RAM is crucial in determining the colors of characters or bitmap graphics displayed on the screen, depending on the active mode.

**Parameters:**
- **Value**: The byte value to be filled into the entire color RAM. This value corresponds to a specific color in the C64 color palette. Since color RAM values are only 4 bits, valid values range from 0 to 15.

**Usage:**
```basic
FillColorMemory(0x0F)  ' This will set all color RAM entries to light gray (assuming standard C64 color codes).
```

**Note**: This subroutine only modifies the color RAM. If you need to change the bitmap graphics or screen memory, you should use the respective subroutines: `FillBitmap(..)` for bitmap memory and `FillScreenMemory(..)` for screen memory. To achieve the intended visual display, ensure consistent and coordinated updates across these memories. Additionally, always ensure that the provided value is within the valid range of 0 to 15 to prevent unintended behaviors.

[Back to TOC](#table-of-contents)

---

### SetColorInRect
#### `SetColorInRect(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE, ColorId AS BYTE)`

This subroutine allows users to change the color of specific regions in the C64 graphics screen.

**Parameters:**
- **x0, y0**: Defines the top-left cell of the rectangle that will be recolored.
- **x1, y1**: Defines the bottom-right cell of the rectangle that will be recolored. The provided rectangle is inclusive of these coordinates.
  - **Valid values**:
    - x0, x1: 0-39 (Representing the horizontal cell index on the screen)
    - y0, y1: 0-24 (Representing the vertical cell index on the screen)

- **Ink**: This specifies the index of the color that you wish to set.
  - For graphics in `HIRES` mode, valid values are `0-1`.
  - For `MULTICOLOR` mode graphics, valid values are `1-3`.

- **ColorId**: This is the actual color code that will be assigned to the specified `Ink` within the rectangle defined by the coordinates.
  - **Valid values**: 0-15 (Representing standard C64 color codes).

**Description**:

Using this subroutine, you can redefine the color of specific regions of the C64's screen. For instance, if you wish to change the background color (Ink 0 in HIRES mode) of a specific screen region to blue, you'd use the appropriate `ColorId` for blue and set `Ink` to 0.

**Example Usage**:

Let's say you want to change the background color of a rectangle that starts from the cell (5,5) and ends at (10,10) to blue in HIRES mode:

```basic
CALL SetColorInRect(5, 5, 10, 10, 0, COLOR_BLUE)
```

Note: Remember to ensure that the specified region (from x0, y0 to x1, y1) lies within the valid screen dimensions and that you choose appropriate values for `Ink` and `ColorId` based on the graphics mode you're operating in.

[Back to TOC](#table-of-contents)

---

### GetPixel
#### GetPixel AS BYTE(x AS WORD, y AS BYTE)

### **Description:**

The `GetPixel()` subroutine allows you to retrieve the bitmap value of a specific pixel at the given coordinates (`x`, `y`) in the `STANDARD_BITMAP_MODE`. It returns the pixel value as a BYTE.

**Parameters:**

- **Coordinates:** You can specify the coordinates of the pixel you want to retrieve using the following parameters:
  - `x`: The horizontal coordinate of the pixel (0-319).
  - `y`: The vertical coordinate of the pixel (0-199).

### **Return Value:**

- `GetPixel()` returns the pixel value as a BYTE value. The value can be one of the following:
  - 0 if the pixel is set to background color
  - 1 if the pixel is set to foreground color

### **Usage Notes:**

- Utilize the `GetPixel()` subroutine when you need to determine the value of a specific pixel in the `STANDARD_BITMAP_MODE`. It can be useful for various pixel-level operations or conditional logic based on pixel color.

- Ensure that the coordinates (`x`, `y`) are within the valid ranges to retrieve accurate pixel color information.

[Back to TOC](#table-of-contents)

---

### GetPixelMC
#### GetPixelMC AS BYTE(x AS BYTE, y AS BYTE)

### **Description:**

The `GetPixelMC()` subroutine allows you to retrieve the bitmap value of a specific pixel at the given coordinates (`x`, `y`) in the `MULTICOLOR_BITMAP_MODE`. It returns the pixel value as a BYTE.

**Parameters:**

- **Coordinates:** You can specify the coordinates of the pixel you want to retrieve using the following parameters:
  - `x`: The horizontal coordinate of the pixel (0-159).
  - `y`: The vertical coordinate of the pixel (0-199).

### **Return Value:**

- `GetPixelMC()` returns the pixel value as a BYTE value. The state is between 0 and 3:
  - 0 if the pixel is set to background color
  - 1 if the pixel color if defined in high nible of screen memory
  - 2 if the pixel color if defined in low nible of screen memory
  - 3 if the pixel color if defined in low nible of color memory

### **Usage Notes:**

- Utilize the `GetPixel()` subroutine when you need to determine the color of a specific pixel in the `STANDARD_BITMAP_MODE`. It can be useful for various pixel-level operations or conditional logic based on pixel color.

- Ensure that the coordinates (`x`, `y`) are within the valid ranges to retrieve accurate pixel color information.

The `GetPixel()` subroutine provides a convenient way to retrieve the color of a specific pixel in the `STANDARD_BITMAP_MODE`, allowing you to perform operations or make decisions based on the pixel's color.

[Back to TOC](#table-of-contents)

---

### Plot
#### Plot(x AS WORD, y AS BYTE, Mode AS BYTE)

The `Plot` subroutine provides a method to draw individual pixels on the screen when operating in `STANDARD_BITMAP_MODE`.

**Parameters:**
- **x**: The horizontal position of the pixel on the screen. Acceptable values range from 0 to 319.
- **y**: The vertical position of the pixel on the screen. Valid values are between 0 and 199.
- **Mode**: The operation mode for the pixel plotting. It can be one of the following constants:
  - `MODE_SET`: Sets the pixel to the foreground color.
  - `MODE_CLEAR`: Sets the pixel to the background color.
  - `MODE_FLIP`: Inverts the current pixel color, switching between background and foreground.

**Usage:**
```basic
CALL Plot(150, 50, MODE_SET)  ' This will set the pixel at position (150, 50) to the foreground color.
```

**Note**: This subroutine is specifically designed for the `STANDARD_BITMAP_MODE`. Ensure that this mode is active before calling `Plot`. If you attempt to use this subroutine in any other mode, results might not be as expected. Always ensure that provided `x` and `y` values are within the valid ranges to prevent unintended behaviors.

[Back to TOC](#table-of-contents)

---

### PlotMC
#### PlotMC(x AS BYTE, y AS BYTE, Ink AS BYTE)

The `PlotMC` subroutine offers a way to draw individual pixels on the screen in multicolor mode.

**Parameters:**
- **x**: The horizontal position of the pixel on the screen in multicolor mode. Valid values range from 0 to 159.
- **y**: The vertical position of the pixel on the screen. Valid values are between 0 and 199.
- **Ink**: Defines the color with which the pixel will be drawn. It can have one of the following values:
  - `0`: Background color (addressed by `$D021`).
  - `1`: Color1, determined by bits #4-7 of the corresponding byte in screen RAM.
  - `2`: Color2, determined by bits #0-3 of the corresponding byte in screen RAM.
  - `3`: Color3, determined by bits #0-3 in the corresponding byte in color RAM range `$D800-$DBFF`.

**Usage:**
```basic
CALL PlotMC(80, 50, 2)  ' This will set the multicolor pixel at position (80, 50) to Color2 as defined in screen RAM.
```

**Note**: Ensure that your system is set to multicolor mode before using this subroutine. Always ensure that the provided `x`, `y`, and `Ink` values are within the valid ranges to prevent unintended behaviors. It's crucial to set up the screen and color RAM appropriately to achieve the desired color results with this subroutine.

[Back to TOC](#table-of-contents)

---

### Draw
#### Draw(x0 AS WORD, y0 AS BYTE, x1 AS WORD, y1 AS BYTE, Mode AS BYTE)

The `Draw` subroutine provides a method to draw a straight line between two points on the screen when operating in `STANDARD_BITMAP_MODE`.

**Parameters:**
- **x0, x1**: The horizontal starting and ending positions of the line on the screen. Acceptable values for each range from 0 to 319.
- **y0, y1**: The vertical starting and ending positions of the line on the screen. Valid values for each range from 0 to 199.
- **Mode**: The operation mode for drawing the line. It can be one of the following constants:
  - `MODE_SET`: Draws the line using the foreground color.
  - `MODE_CLEAR`: Draws the line using the background color.
  - `MODE_FLIP`: Inverts the color of the pixels on the line's path, toggling between background and foreground.

**Usage:**
```basic
CALL Draw(10, 10, 150, 190, MODE_SET)  ' This will draw a line from point (10, 10) to point (150, 190) using the foreground color.
```

**Note**: This subroutine is specifically designed for the `STANDARD_BITMAP_MODE`. It's essential to ensure that this mode is active before invoking `Draw`. Using this subroutine in other modes might produce unexpected results. Always ensure that the provided `x0`, `y0`, `x1`, `y1`, and `Mode` values are within the valid ranges to avoid unintended behaviors.

[Back to TOC](#table-of-contents)

---

### DrawMC
#### DrawMC(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE)

The `DrawMC` subroutine facilitates drawing straight lines on the screen in multicolor mode.

**Parameters:**
- **x0, x1**: The horizontal starting and ending positions of the line on the screen in multicolor mode. Valid values for each range from 0 to 159.
- **y0, y1**: The vertical starting and ending positions of the line on the screen. Acceptable values for each are between 0 and 199.
- **Ink**: Specifies the color to be used to draw the line. It can have one of the following values:
  - `0`: Background color (addressed by `$D021`).
  - `1`: Color1, determined by bits #4-7 of the corresponding byte in screen RAM.
  - `2`: Color2, determined by bits #0-3 of the corresponding byte in screen RAM.
  - `3`: Color3, determined by bits #0-3 in the corresponding byte in color RAM range `$D800-$DBFF`.

**Usage:**
```basic
CALL DrawMC(20, 30, 140, 170, 2)  ' This will draw a line in multicolor mode from point (20, 30) to point (140, 170) using Color2 as defined in screen RAM.
```

**Note**: Before employing the `DrawMC` subroutine, ensure that your system is configured in multicolor mode. Set up the screen and color RAM appropriately to get the desired color results. Always verify that the provided `x0`, `y0`, `x1`, `y1`, and `Ink` values fall within the legitimate ranges to prevent unexpected outcomes. Using this subroutine in non-multicolor modes might yield unpredictable results.

[Back to TOC](#table-of-contents)

---

### HDraw
#### HDraw(x0 AS WORD, x1 AS WORD, y AS BYTE, Mode AS BYTE)

The `HDraw()` subroutine is designed to draw horizontal lines efficiently in the `STANDARD_BITMAP_MODE`. It provides a faster way to render horizontal lines compared to the more general-purpose `Draw()` subroutine. Users can specify the starting and ending horizontal coordinates (`x0` and `x1`), the vertical coordinate (`y`), and the drawing mode (`Mode`).

**Parameters:**
- **x0, x1**: The horizontal starting and ending positions of the line on the screen. Acceptable values for each range from 0 to 319.
- **y**: The vertical position of the line on the screen. Valid values for each range from 0 to 199.
- **Mode**: The operation mode for drawing the line. It can be one of the following constants:
  - `MODE_SET`: Draws the line using the foreground color.
  - `MODE_CLEAR`: Draws the line using the background color.
  - `MODE_FLIP`: Inverts the color of the pixels on the line's path, toggling between background and foreground.

**Usage:**
```basic
CALL HDraw(10, 100, 190, MODE_SET)  ' This will draw a horizontal line from point (10, 190) to point (100, 190) using the foreground color.
```

### **Usage Notes:**

- Utilize `HDraw()` when you need to draw horizontal lines efficiently in the `STANDARD_BITMAP_MODE`. It is a high-performance alternative to the more generic `Draw()` subroutine.

- Ensure that `x0` and `x1` are within the valid horizontal coordinate range of 0 to 319, and `y` is within the range of 0 to 199.


[Back to TOC](#table-of-contents)

---

### HDrawMC
#### HDrawMC(x0 AS BYTE, x1 AS BYTE, y AS BYTE, Ink AS BYTE)

The `HDrawMC()` subroutine is designed to draw horizontal lines efficiently in the `MULTICOLOR_BITMAP_MODE`. It provides a faster way to render horizontal lines compared to the more general-purpose `DrawMC()` subroutine. Users can specify the starting and ending horizontal coordinates (`x0` and `x1`), the vertical coordinate (`y`), and the drawing color (`Ink`).

**Parameters:**
- **x0, x1**: The horizontal starting and ending positions of the line on the screen. Acceptable values for each range from 0 to 159.
- **y**: The vertical position of the line on the screen. Valid values for each range from 0 to 199.
- **Mode**: The operation mode for drawing the line. It can be a color index 0-3.

**Usage:**
```basic
CALL HDrawMC(10, 100, 190, 2)  ' This will draw a horizontal line from point (10, 190) to point (100, 190) using the color index 2.
```

### **Usage Notes:**

- Ensure that `x0` and `x1` are within the valid horizontal coordinate range of 0 to 159, and `y` is within the range of 0 to 199.


[Back to TOC](#table-of-contents)

---

### VDraw
#### VDraw(x AS WORD, y0 AS BYTE, y1 AS BYTE, Mode AS BYTE)

The `VDraw()` subroutine is designed to draw vertical lines efficiently in the `STANDARD_BITMAP_MODE`. It provides a faster way to render vertical lines compared to the more general-purpose `Draw()` subroutine. Users can specify the starting and ending vertical coordinates (`y0` and `y1`), the horizontal coordinate (`x`), and the drawing mode (`Mode`).

**Parameters:**
- **x**: The horizontal position of the line on the screen. Acceptable values for each range from 0 to 319.
- **y0, y1**: The vertical starting and ending positions of the line on the screen. Acceptable values for each range from 0 to 199.
- **Mode**: The operation mode for drawing the line. It can be one of the following constants:
  - `MODE_SET`: Draws the line using the foreground color.
  - `MODE_CLEAR`: Draws the line using the background color.
  - `MODE_FLIP`: Inverts the color of the pixels on the line's path, toggling between background and foreground.

**Usage:**
```basic
CALL VDraw(10, 100, 190, MODE_SET)  ' This will draw a vertical line from point (10, 100) to point (10, 190) using the foreground color.
```

### **Usage Notes:**

- Utilize `VDraw()` when you need to draw vertical lines efficiently in the `STANDARD_BITMAP_MODE`. It is a high-performance alternative to the more generic `Draw()` subroutine.

- Ensure that `y0` and `y1` are within the valid vertical coordinate range of 0 to 199, and `x` is within the range of 0 to 319.


[Back to TOC](#table-of-contents)

---

### VDrawMC
#### VDrawMC(x AS BYTE, y0 AS BYTE, y1 AS BYTE, Ink AS BYTE)

The `VDrawMC()` subroutine is designed to draw vertical lines efficiently in the `MULTICOLOR_BITMAP_MODE`. It provides a faster way to render vertical lines compared to the more general-purpose `DrawMC()` subroutine. Users can specify the starting and ending vertical coordinates (`y0` and `y1`), the horizontal coordinate (`x`), and the drawing color index (`Ink`).

**Parameters:**
- **x**: The horizontal position of the line on the screen. Acceptable values for each range from 0 to 159.
- **y0, y1**: The vertical starting and ending positions of the line on the screen. Acceptable values for each range from 0 to 199.
- **Ink**: The color index for drawing the line. It can range from 0 to 3.

**Usage:**
```basic
CALL VDrawMC(10, 100, 190, 3)  ' This will draw a vertical line from point (10, 100) to point (10, 190) using color index 3.
```

### **Usage Notes:**

- Ensure that `y0` and `y1` are within the valid vertical coordinate range of 0 to 199, and `x` is within the range of 0 to 159.


[Back to TOC](#table-of-contents)

---

### Circle
#### Circle(x0 AS WORD, y0 AS BYTE, Radius AS BYTE, Mode AS BYTE, BgMode AS BYTE)

The `Circle` subroutine enables drawing circles in the `STANDARD_BITMAP_MODE` on the screen.

**Parameters:**
- **x0**: The horizontal position of the circle's center. Valid values range from 0 to 319.
- **y0**: The vertical position of the circle's center. Acceptable values range from 0 to 199.
- **Radius**: Defines the radius of the circle in pixels.
- **Mode**: The operation mode for drawing the circle. It can be one of the following constants:
  - `MODE_SET`: Draws the circle using the foreground color.
  - `MODE_CLEAR`: Draws the circle using the background color.
  - `MODE_FLIP`: Inverts the color of the pixels on the circle's circumference, toggling between background and foreground.
  - `MODE_TRANSPARENT`: Does not draw the circumference.
- **BgMode**: The operation mode for drawing the circle. It can be one of the following constants:
  - `MODE_SET`: Draws the circle using the foreground color.
  - `MODE_CLEAR`: Draws the circle using the background color.
  - `MODE_FLIP`: Inverts the color of the pixels inside the circle, toggling between background and foreground.
  - `MODE_TRANSPARENT`: Does not draw the insides of the circle.
**Usage:**
```basic
CALL Circle(150, 100, 40, MODE_SET, MODE_TRANSPARENT)  ' This draws a circle centered at point (150, 100) with a radius of 40 pixels using the foreground color.
```

**Note**: The `Circle` subroutine is specifically designed for the `STANDARD_BITMAP_MODE`. Before calling this subroutine, ensure that the correct mode is active. Pixels drawn must be within the screen boundaries; always ensure that the combination of the center (`x0`, `y0`) and `Radius` will result in a circle completely inside the screen dimensions to avoid unexpected behaviors. Using this subroutine outside the `STANDARD_BITMAP_MODE` might produce unpredictable results.

[Back to TOC](#table-of-contents)

---

### CircleMC
#### CircleMC(x0 AS BYTE, y0 AS BYTE, Radius AS BYTE, Ink AS BYTE, FillInk AS BYTE)

The `CircleMC` subroutine is tailored for drawing circles in multicolor mode on the screen.

**Parameters:**
- **x0**: The horizontal position of the circle's center in multicolor mode. Acceptable values range from 0 to 159.
- **y0**: The vertical position of the circle's center. Valid values range from 0 to 199.
- **Radius**: Defines the radius of the circle in pixels. Note that library compensates multicolor mode's pixel height/width ratio by drawing in reality an ellipse where x axel is only half of the defined radius.
- **Ink**: Specifies the color to be used to draw the circle. It can have one of the following values:
  - `0`: Background color (addressed by `$D021`).
  - `1`: Color1, determined by bits #4-7 of the corresponding byte in screen RAM.
  - `2`: Color2, determined by bits #0-3 of the corresponding byte in screen RAM.
  - `3`: Color3, determined by bits #0-3 in the corresponding byte in color RAM range `$D800-$DBFF`.
  - `MODE_TRANSPARENT`: Does not draw the circles circumference.
- **FillInk**: Specifies the color to be used to draw the insides of the circle. It can have one of the following values:
  - `0`: Background color (addressed by `$D021`).
  - `1`: Color1, determined by bits #4-7 of the corresponding byte in screen RAM.
  - `2`: Color2, determined by bits #0-3 of the corresponding byte in screen RAM.
  - `3`: Color3, determined by bits #0-3 in the corresponding byte in color RAM range `$D800-$DBFF`.
  - `MODE_TRANSPARENT`: Does not draw the insides of the circle.

**Usage:**
```basic
CALL CircleMC(80, 100, 40, 2, MODE_TRANSPARENT)  ' This will draw a circle centered at point (80, 100) with a radius of 40 pixels using Color2 as defined in screen RAM.
```

**Note**: The `CircleMC` subroutine is specifically devised for use in multicolor mode. Before using this subroutine, ensure that your system is configured to this mode. Pixels drawn must be within the screen boundaries; make sure that the combination of center (`x0`, `y0`) and `Radius` keeps the circle entirely inside the screen dimensions to prevent unexpected behaviors. Using this subroutine outside of multicolor mode can yield unpredictable outcomes.

[Back to TOC](#table-of-contents)

---

### Rect
#### Rect(x0 AS WORD, y0 AS BYTE, x1 AS WORD, y1 AS BYTE, Mode AS BYTE, FillMode AS BYTE)

The `Rect()` subroutine is used to draw rectangles in the `STANDARD_BITMAP_MODE`. You can define the position and size of the rectangle using coordinates (`x0`, `y0`, `x1`, `y1`) and choose the drawing mode (`Mode`) to rectangle frame and (`FillMode`) interior sparately.

**Parameters:**

- **Coordinates:** You can specify the position and size of the rectangle using the following parameters:
  - `x0`: The horizontal coordinate of the top-left corner of the rectangle (0-319).
  - `y0`: The vertical coordinate of the top-left corner of the rectangle (0-199).
  - `x1`: The horizontal coordinate of the bottom-right corner of the rectangle (0-319).
  - `y1`: The vertical coordinate of the bottom-right corner of the rectangle (0-199).

- **Drawing Modes:** The `Mode` parameter defines the drawing mode for rectangle frame. It can take one of the following constants:
  - `MODE_SET`: Sets pixels to the foreground color.
  - `MODE_CLEAR`: Sets pixels to the background color.
  - `MODE_FLIP`: Flips the current pixel color from background to foreground or vice versa.
  - `MODE_TRANSPARENT`: Does not draw the edges

- **Fill Modes:** The `FillMode` parameter defines how interior of the rectangle is drawn. It can also take one of the following constants:
  - `MODE_SET`: Fills the rectangle with the foreground color.
  - `MODE_CLEAR`: Clears the pixels within the rectangle.
  - `MODE_FLIP`: Flips the color of the pixels within the rectangle.
  - `MODE_TRANSPARENT`: Renders the rectangle as hollow, leaving its interior transparent.

### **Usage Notes:**

- Use the `Rect()` subroutine when you need to draw rectangles in the `STANDARD_BITMAP_MODE`. You can control the drawing mode and fill mode to achieve various visual effects, including filled or hollow rectangles.


[Back to TOC](#table-of-contents)

---

### RectMC
#### RectMC(x0 AS BYTE, y0 AS BYTE, x1 AS BYTE, y1 AS BYTE, Ink AS BYTE, FillInk AS BYTE)

The `RectMC()` subroutine is used to draw rectangles in the `MULTICOLOR_BITMAP_MODE`. You can define the position and size of the rectangle using coordinates (`x0`, `y0`, `x1`, `y1`) and choose the drawing color (`Ink`) to rectangle frame and (`FillInk`) to interior sparately.

**Parameters:**

- **Coordinates:** You can specify the position and size of the rectangle using the following parameters:
  - `x0`: The horizontal coordinate of the top-left corner of the rectangle (0-159).
  - `y0`: The vertical coordinate of the top-left corner of the rectangle (0-199).
  - `x1`: The horizontal coordinate of the bottom-right corner of the rectangle (0-159).
  - `y1`: The vertical coordinate of the bottom-right corner of the rectangle (0-199).

- **Ink:** The `Ink` parameter defines the drawing color for rectangle frame. It can take numerical values from 0 to 3 and constant MODE_TRANSPARENT or MODE_FLIP
  - `MODE_FLIP`: Flips the current pixel color from background to foreground or vice versa.
  - `MODE_TRANSPARENT`: Does not draw the edges
- **FillInk:** The `FillInk` parameter defines how interior of the rectangle is drawn. It can also take numerical values from 0 to 3 and constant MODE_TRANSPARENT or MODE_FLIP:
  - `MODE_FLIP`: Flips the color of the pixels within the rectangle.
  - `MODE_TRANSPARENT`: Renders the rectangle as hollow, leaving its interior transparent.

### **Usage Notes:**

- Use the `RectMC()` subroutine when you need to draw rectangles in the `MULTICOLOR_BITMAP_MODE`. You can control the drawing mode and fill mode to achieve various visual effects, including filled or hollow rectangles.

[Back to TOC](#table-of-contents)

---

### CopyCharROM
#### CopyCharROM(CharSet AS BYTE, DestAddr AS WORD)

The `CopyCharROM` subroutine facilitates the copying of character sets from ROM to a designated RAM location. This is particularly useful when you wish to modify the character set or to ensure that the character set resides in a specific memory location for display purposes.

**Parameters:**
- **CharSet**: Determines which character set to copy from the ROM.
  - `0`: Uppercase/Graphics character set.
  - `1`: Lowercase/Uppercase character set.

- **DestAddr**: This is the absolute memory location in RAM, spanning the entire 64k memory, where the character set will be copied to. Ensure that the address provided has space for 2048 bytes of character data. If you plan to use the copied characters in text-based modes, the `DestAddr` should align to a 2048-byte boundary within your selected 16k VIC bank.

**Usage:**
```basic
CALL CopyCharROM(0, $b000)  ' This will copy the Uppercase/Graphics character set to the memory location starting at 45056.
```

**Note**: Before invoking this subroutine, it's crucial to verify that the `DestAddr` is correctly set to ensure that no unexpected memory overlap occurs. It's imperative to remember that the `DestAddr` is an absolute address, not relative to the current VIC bank. If used in text modes, ensuring alignment to the 2048-byte boundary is essential for the correct display of characters.

[Back to TOC](#table-of-contents)

---

### TextMC
#### TextMC(Col AS BYTE, Row AS BYTE, Ink AS BYTE, Bg AS BYTE, Double AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD)

The `TextMC` subroutine offers the ability to draw text on the screen in the multicolor bitmap mode. Unlike pixel-based drawing, with this subroutine, you define the 4x8 cell on the screen where the text begins. The design of the displayed text depends on the character memory address provided.

**Parameters:**
- **Col**: Column index (4x8 cell) where the text starts. Valid range: `0-39`.

- **Row**: Row index (4x8 cell) where the text starts. Valid range: `0-24`.

- **Ink**: Defines the color used for the text's shapes. Possible values include `MODE_TRANSPARENT` (to leave the bitmap untouched for the letter shape) or a value from `0-3` representing the desired color.

- **Bg**: Defines the background color for the text. It can be set to `MODE_TRANSPARENT` (to leave the bitmap as is for the letter's background) or a color value from `0-3`.

- **Double**: Option to enlarge each letter to span across 2 cells horizontally.
  - `0`: FALSE - Regular width.
  - `$FF`: TRUE - Double width.

- **Text**: A string of up to 40 characters. This subroutine does not recognize special codes. The actual shape drawn to the screen corresponds to the `CharMemAddr`. Each character in the string is converted from PETSCII to the C64 screen code, and the resulting pattern from the Character memory is rendered on screen.

- **CharMemAddr**: Specifies the address within the 64k address space pointing to the character memory. This address can be outside the current VIC bank. Additionally, special constant values can be used:
  - **ROM_CHARSET_UPPERCASE**: Uses the uppercase/graphics character set directly from the C64's ROM.
  - **ROM_CHARSET_LOWERCASE**: Uses the lowercase/uppercase character set directly from the C64's ROM.

**Usage:**
```basic
CALL TextMC(10, 5, 1, 2, 0, "HELLO WORLD", 8192);
```

**Note**: With `TextMC`, the displayed characters derive their design from the provided character memory address (`CharMemAddr`). If you've customized or modified the character set in memory, the displayed text will reflect these changes. Always ensure that the `CharMemAddr` points to valid character data to avoid unexpected display results.

[Back to TOC](#table-of-contents)

---

### Text
#### Text(Col AS BYTE, Row AS BYTE, Mode AS BYTE, BgMode AS BYTE, Double AS BYTE, Text AS STRING * 40, CharMemAddr AS WORD)

The `Text` subroutine offers a flexible way to display text on the screen. This method provides options to control the display mode of the text, its background, and the potential to double its width. You'll specify the starting position in terms of the 8x8 cells rather than pixel coordinates.

**Parameters:**
- **Col**: Column index (8x8 cell) where the text will begin. Valid range: `0-39`.

- **Row**: Row index (8x8 cell) where the text will begin. Valid range: `0-24`.

- **Mode**: Determines the display mode for the text.
  - **MODE_SET**: Sets text to the foreground color.
  - **MODE_CLEAR**: Sets text to the background color.
  - **MODE_TRANSPARENT**: Leaves the pixels unchanged.

- **BgMode**: Determines the mode for the text's background.
  - **MODE_SET**: Sets the background to the foreground color.
  - **MODE_CLEAR**: Sets the background to the background color.
  - **MODE_TRANSPARENT**: Leaves the pixels unchanged.

- **Double**: Option to enlarge each letter's width to span 2 cells.
  - `0`: FALSE - Regular width.
  - `$FF`: TRUE - Double width.

- **Text**: A string of up to 40 characters. The subroutine does not process special codes. Each character gets converted from PETSCII to C64 screen code, and the corresponding pattern from the Character memory is then displayed.

- **CharMemAddr**: Specifies the address within the 64k address space pointing to the character memory. This address can be outside the current VIC bank. Additionally, special constant values can be used:
  - **ROM_CHARSET_UPPERCASE**: Uses the uppercase/graphics character set directly from the C64's ROM.
  - **ROM_CHARSET_LOWERCASE**: Uses the lowercase/uppercase character set directly from the C64's ROM.

**Usage:**
```basic
CALL Text(15, 10, MODE_SET, MODE_CLEAR, 0, "HELLO C64", ROM_CHARSET_UPPERCASE);
```

**Note**: The `Text` subroutine displays characters based on the provided character memory address (`CharMemAddr`). Customizations or changes made to the character set in RAM will be reflected in the displayed text. When using the ROM-based constants (ROM_CHARSET_UPPERCASE or ROM_CHARSET_LOWERCASE), it will directly utilize the respective character sets from the C64's internal ROM. Ensure that the `CharMemAddr` always points to valid character data to prevent unpredictable results.

[Back to TOC](#table-of-contents)

---

### PetsciiToScreenCode
#### PetsciiToScreenCode(Petscii AS BYTE) -> BYTE

The `PetsciiToScreenCode` function is designed to convert a given PETSCII value into its corresponding C64 screen code value. This conversion is necessary when working directly with the C64's video hardware, as the native character encoding used in the C64's ROM and by many software applications is PETSCII, whereas the C64 video memory utilizes a different set of codes, known as screen codes, to represent characters.

**Parameters:**
- **Petscii**: The PETSCII value you wish to convert. It's an 8-bit byte representing a character in the PETSCII encoding.

**Returns:**
- An 8-bit byte representing the corresponding screen code for the provided PETSCII character.

**Usage:**
```basic
SCREEN_CODE = PetsciiToScreenCode(PETSCII_CHAR);
```

**Note**: Not all PETSCII characters have direct representations in the C64's screen code set. When converting, it's a good idea to verify that the resulting screen code corresponds to the desired character visually, especially if you're working with special or non-printable PETSCII characters.

**Additional Note**: Most developers will not need to call this function directly. The `Text(...)` and `TextMC(...)` subroutines internally call this function to handle the conversion of characters. It's provided as part of the API for those who might have specialized use cases or for deeper insights into the library's internal operations.

## Contribution

We welcome contributions to the XCB3-GFX library. Please read the contribution guidelines before submitting a pull request.

## License

This project is licensed under the BSD 2-Clause License License. See `LICENSE` for details.

---

Created by Orlof. For further details or queries, feel free to reach out.
