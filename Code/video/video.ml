module type VideoFunctor = 
functor (Img : Image.S) ->
sig
  type vid

  val fps: vid -> int

  val load: string -> int -> vid
  val close: vid -> int
  val is_finished: vid -> bool
  val new_frame: vid -> Img.img
end

module Vid : VideoFunctor = 
functor (Img : Image.S) ->
struct
  type vid = {
    fps: int;
    folder: string;
    mutable frame_id: int;
    nb_frames: int;
  }

  let fps video =
    video.fps

  let is_finished video =
    video.frame_id >= video.nb_frames

  let read_frame folder frame_id =
    Img.read (Filename.concat folder ((string_of_int frame_id) ^ "." ^ Img.extension))

  let new_frame video =
    if is_finished video then video.frame_id <- 0;
    video.frame_id <- video.frame_id + 1;
    read_frame video.folder video.frame_id

  let load filename fps =
    let folder = Filename.chop_extension filename in
    let sfps = string_of_int fps in
    let extract_frames () =
      let _ = Sys.command ("mkdir " ^ folder) in ();
      let _ = Sys.command ("ffmpeg -i " ^ filename ^ " -r " ^ sfps ^ " " ^ folder ^ "/%d." ^ Img.extension) in ()
    in      
    let _ =
      try (
        if not(Sys.is_directory folder) then extract_frames ()
      ) with Sys_error(_) -> extract_frames ()
    in

    { fps = fps;
      folder = folder;
      frame_id = 0;
      nb_frames = Array.length (Sys.readdir folder) }

  let close video =
    Sys.command ("rm -r " ^ video.folder)
end

module AbstractVideo = (Vid : VideoFunctor);;
