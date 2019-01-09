#include <windows.h>
#include <windowsx.h>
#include <stdio.h>

const char* TITLE_PROGRAM="Imperia Online Разграбване Калкулатор ver.2.01b Copyright(c) by Mony Dochev";
const char* CLASS_DBGRID="TDBGrid";

typedef int (*callback_t)(HWND hWnd, void* param);

HWND SearchWindow(HWND hWnd, callback_t callback, void* param)
{
	HWND win=GetWindow(hWnd, GW_HWNDFIRST);
	while (win)
	{
		if (callback(win, param)) return win;
		if (SearchWindow(GetFirstChild(win), callback, param)) break;
		win=GetWindow(win, GW_HWNDNEXT);
	}
	return 0;
}

typedef struct 
{
	char* title;
	char* clazz;
	HWND hWnd;
} search_t;

int search_callback(HWND hWnd, void* param)
{
	static HWND hWndFound=0;
	static char text[256];
	static char clazz[256];
	search_t* search_info=(search_t*)param;

	GetWindowText(hWnd, text, 256);
	GetClassName(hWnd, clazz, 256);
	printf("0x%X %s (%s)\n", hWnd, text, clazz);
	if ( (search_info->title && strcmp(text, search_info->title) == 0) || (search_info->clazz && strcmp(clazz, search_info->clazz) == 0))
	{
		search_info->hWnd=hWnd;
		return 0;
	}
	return 0;
}

int main()
{
	search_t search;
	HWND hWndMain;

	/* find siege calculator program */
	search.title=TITLE_PROGRAM;
	search.clazz=0;
	search.hWnd=0;
	SearchWindow(GetFirstChild(GetDesktopWindow()), search_callback, &search);
	hWndMain=search.hWnd;
	if (!hWndMain)
	{
		printf("Unable to find the Siege Calculator\n");
	}
	else
	{
		// Here you can hack hWndMain as you wish
	}
	return 0;
}
