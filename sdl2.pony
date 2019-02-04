use "lib:SDL2"
use "debug"

use @SDL_Init[I32](flags: U32)
use @SDL_WasInit[I32]()
use @SDL_Quit[None]()
use @SDL_GetVersion[None](version: MaybePointer[SDLVersion])
use @SDL_GetError[Pointer[U8 val]]()
use @SDL_CreateWindow[SDLWindowRaw ref](name: Pointer[U8 val] tag, x: I32, y: I32, w: I32, h: I32, flags: U32)
use @SDL_CreateRenderer[SDLRendererRaw ref](window: SDLWindowRaw box, index: I32, flags: U32)
use @SDL_RenderClear[I32](renderer: SDLRendererRaw ref)
use @SDL_RenderPresent[None](renderer: SDLRendererRaw ref)
use @SDL_SetRenderDrawColor[I32](renderer: SDLRendererRaw ref, red: U8, green: U8, blue: U8, alpha: U8)

use @SDL_BlitSurface[I32](src: SDLSurfaceRaw box, srcrect: SDLRectRaw, dst: SDLSurfaceRaw ref, dstrect: SDLRectRaw)
use @SDL_CreateTextureFromSurface[SDLTextureRaw](renderer: SDLRendererRaw box, surface: SDLSurfaceRaw box)
use @SDL_RenderCopy[I32](renderer: SDLRendererRaw ref, texture: SDLTextureRaw, srcrect: SDLRectRaw, dstrect: SDLRectRaw)

primitive _SDLWindow
type SDLWindowRaw is Pointer[_SDLWindow]

struct _SDLRendererRaw
type SDLRendererRaw is Pointer[_SDLRendererRaw]

struct _SDLTextureRaw
type SDLTextureRaw is Pointer[_SDLTextureRaw]

struct SDLVersion
  let major: U8
  let minor: U8
  let patch: U8

  new create(major': U8, minor': U8, patch': U8) =>
    major = major'
    minor = minor'
    patch = patch'

primitive SDL
  """
  *Where it all started.*

  Almost every call passed to SDL2 go through these functions.
  Especially, the `SDL.init()` resides here. You'll have to call it yourself, as it may fail.

  If a method result in an error, `SDL.get_error()` will become your friend, use it as much as possible!

  **Basic usage example:**
  ```pony
    use "sdl2"

    actor Main
      new create(env: Env) =>
        try
          SDL.init()?
          post_init()
        else
          env.out.print("Couldn't initialize SDL2, quitting!")
        end

      fun post_init() =>
        // create a window
        let window = SDLWindow("My SDL2 project!", SDLWindowPosCentered, SDLWindowPosCentered, 640, 480)
        // create a renderer for the window
        let renderer = SDLRenderer(window, -1, [SDLRendererAccelerated])
        // set the renderer's draw color
        renderer.set_draw_color(SDLColor(16, 16, 16))
        // clear the renderer (filling it with the color)
        renderer.clear()
        // update the window
        renderer.present()
  ```
  """

  fun init(flags: (Array[SDLInitFlag] val | U32) = 100000)? =>
    if not was_init() then
      if not _sdl_init(flags) then
        error
      end
    end

  fun was_init(): Bool =>
    @SDL_WasInit() != 0

  fun quit() =>
    if was_init() then @SDL_Quit() end

  fun _final() =>
    quit()

  fun version(): (U8, U8, U8) =>
    var v = SDLVersion(0, 0, 0)
    @SDL_GetVersion(MaybePointer[SDLVersion](v))
    (v.major, v.minor, v.patch)

  fun get_error(): String =>
    recover String.from_cstring(@SDL_GetError()) end

  fun _sdl_init(flags: (Array[SDLInitFlag] val | U32)): Bool =>
    var flag: U32 = 0
    match flags
    | let flags': Array[SDLInitFlag] val =>
      for flag' in flags'.values() do
        flag = flag or flag'()
      end
    | let flag': U32 => flag = flag'
    end
    @SDL_Init(flag) == 0

  fun create_window(name: String, x: (I32 | SDLWindowPosCentered | SDLWindowPosUndefined), y: (I32 | SDLWindowPosCentered | SDLWindowPosUndefined), w: I32, h: I32, flags: (Array[SDLWindowFlag] val | U32) = 0): SDLWindowRaw =>
    let x' = match x
    | let x'': I32 => x''
    | SDLWindowPosCentered => SDLWindowPosCentered()
    | SDLWindowPosUndefined => SDLWindowPosUndefined()
    end
    let y' = match y
    | let y'': I32 => y''
    | SDLWindowPosCentered => SDLWindowPosCentered()
    | SDLWindowPosUndefined => SDLWindowPosUndefined()
    end
    var flags': U32 = 0
    match flags
    | let flags'': Array[SDLWindowFlag] val =>
      for flag in flags''.values() do
        flags' = flags' or flag()
      end
    | let flags'': U32 => flags' = flags''
    end

    @SDL_CreateWindow(name.cstring(), x', y', w, h, flags')

  fun create_renderer(window: SDLWindow, index: I32, flags: (Array[SDLRendererFlag] val | U32) = 1): SDLRendererRaw ref =>
    var flags': U32 = 0
    match flags
    | let flags'': Array[SDLRendererFlag] val =>
      for flag in flags''.values() do
        flags' = flags' or flag()
      end
    | let flags'': U32 => flags' = flags''
    end

    @SDL_CreateRenderer(window.get_raw(), index, flags')

  fun render_clear(renderer: SDLRendererRaw ref): Bool =>
    @SDL_RenderClear(renderer) == 0

  fun render_present(renderer: SDLRendererRaw ref) =>
    @SDL_RenderPresent(renderer)

  fun set_render_draw_color(renderer: SDLRendererRaw ref, r: U8, g: U8, b: U8, a: U8 = 255): Bool =>
    @SDL_SetRenderDrawColor(renderer, r, g, b, a) == 0

class SDLWindow
  let _window: SDLWindowRaw ref
  let width: I32
  let height: I32
  let name: String

  new create(name': String, x: (I32 | SDLWindowPosCentered | SDLWindowPosUndefined), y: (I32 | SDLWindowPosCentered | SDLWindowPosUndefined), width': I32, height': I32, flags: (Array[SDLWindowFlag] val | U32) = 0) =>
    width = width'
    height = height'
    name = name'
    _window = SDL.create_window(name, x, y, width, height, flags)

  fun ref get_raw(): SDLWindowRaw ref =>
    _window

class SDLColor
  let _r: U8
  let _g: U8
  let _b: U8
  let _a: U8

  new val create(r: U8, g: U8, b: U8, a: U8 = 255) =>
    _r = r
    _g = g
    _b = b
    _a = a

  fun red(): U8 => _r
  fun green(): U8 => _g
  fun blue(): U8 => _b
  fun alpha(): U8 => _a

  fun to_raw(): U32 =>
    (_a.u32() * 256 * 256 * 256) + (_b.u32() * 256 * 256) + (_g.u32() * 256) + (_r.u32())
    // SDLColorRaw(_r, _g, _b, _a)

// Pony structs are passed by reference, so we have to map by hand the values to a U32
type SDLColorRaw is U32

primitive _SDLSurface

class SDLSurface
  let _raw: SDLSurfaceRaw ref

  new create(raw: SDLSurfaceRaw ref) =>
    _raw = raw

  fun ref get_raw(): SDLSurfaceRaw ref =>
    _raw

  fun blit(surface: SDLSurface, from: (SDLRect | (I32, I32, I32, I32) | None), to: (SDLRect | (I32, I32, I32, I32) | None)): Bool =>
    let from' = match from
    | let rect: SDLRect => rect
    | (let x: I32, let y: I32, let width: I32, let height: I32) => SDLRect(x, y, width, height)
    | None => SDLRect.none()
    end
    let to' = match to
    | let rect: SDLRect => rect
    | (let x: I32, let y: I32, let width: I32, let height: I32) => SDLRect(x, y, width, height)
    | None => SDLRect.none()
    end
    @SDL_BlitSurface(_raw, from'.get_raw(), surface.get_raw(), to'.get_raw()) == 0

type SDLSurfaceRaw is (Pointer[_SDLSurface])

struct _SDLRect
  let x: I32
  let y: I32
  let width: I32
  let height: I32

  new create(x': I32, y': I32, width': I32, height': I32) =>
    x = x'
    y = y'
    width = width'
    height = height'

type SDLRectRaw is MaybePointer[_SDLRect ref]

class SDLRect
  let _raw: SDLRectRaw ref

  new create(x: I32, y: I32, width: I32, height: I32) =>
    _raw = SDLRectRaw(_SDLRect(x, y, width, height))

  new from_raw(raw: SDLRectRaw) =>
    _raw = raw

  new none() =>
    _raw = SDLRectRaw.none()

  fun ref get_raw(): SDLRectRaw ref =>
    _raw

  fun apply(): ((I32, I32, I32, I32) | None) =>
    """
    Gives you the values of the internal SDL_Rect
    """
    try
      let rect = _raw.apply()?
      (rect.x, rect.y, rect.width, rect.height)
    else
      None
    end

// struct SDLPixelFormatRaw
//   let format: U32
//
// struct SDLSurfaceRaw
//   let _flags: U32
//   let format: SDLPixelFormatRaw
//   let width: I32
//   let height: I32
//   let pitch: I32

class SDLTexture
  let _raw: SDLTextureRaw ref

  new create(raw: SDLTextureRaw ref) =>
    _raw = raw

  fun ref get_raw(): SDLTextureRaw ref =>
    _raw
