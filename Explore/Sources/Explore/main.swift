import ElementaryUI

// Two mount points on one page: the interactive map and controls, and the code panel further
// down. Both read the shared `explorer`.
Application(LabView()).mount(in: "#app")
Application(CodePanel()).mount(in: "#code")
