/**
 * TypeScript definitions for NeXT global variables
 * These extend the standard Duet3D object model types
 */

declare module "@duet3d/objectmodel" {
	interface ObjectModelGlobal {
		// NeXT UI State
		nxtUiReady?: boolean;
		
		// NeXT Custom Dialog System
		nxtDialogActive?: boolean;
		nxtDialogMessage?: string | null;
		nxtDialogTitle?: string | null;
		nxtDialogChoices?: Array<string> | null;
		nxtDialogHasChoices?: boolean;
		nxtDialogFlag?: number;
		nxtDialogResponse?: number | null;
		nxtDialogSeq?: number | null;
	}
}