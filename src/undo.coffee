UndoManager = hg.struct
  undoStates: hg.array []
  redoStates: hg.array []
  canUndo: hg.value false
  canRedo: hg.value false

UndoManager.undo = (um, state) ->
  if um.canUndo
    um.redoStates.push um.undoStates.shift(0)
    state.set um.undoStates.get(0)
    um.canUndo.set not um.undoStates().length
    um.canRedo.set true

UndoManager.redo = (um, state) ->
  if um.canRedo
    #um.undoStates.push um.redoStates
    #um.undoStates = Mori.conj um.undoStates, Mori.first um.redoStates
    #state = Mori.first um.redoStates
    #um.redoStates = Mori.drop 1, um.redoStates
    #um.canRedo = not Mori.is_empty um.redoStates
    #um.canUndo = true

