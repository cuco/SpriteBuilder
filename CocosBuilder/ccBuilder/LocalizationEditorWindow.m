//
//  LocalizationEditorWindow.m
//  SpriteBuilder
//
//  Created by Viktor on 8/6/13.
//
//

#import "LocalizationEditorWindow.h"
#import "LocalizationEditorLanguage.h"
#import "LocalizationEditorHandler.h"
#import "LocalizationEditorTranslation.h"
#import "AppDelegate.h"
#import "CCBTextFieldCell.h"
#import "NSPasteboard+CCB.h"

@implementation LocalizationEditorWindow

#pragma mark Init and Updating stuff

- (void) awakeFromNib
{
    [tableTranslations registerForDraggedTypes:[NSArray arrayWithObject:@"com.cocosbuilder.LocalizationEditorTranslation"]];
    [self populateLanguageAddMenu];
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self addLanguageColumns];
    [self updateQuickEditLangs];
}

- (void) populateLanguageAddMenu
{
    NSArray* langs = [AppDelegate appDelegate].localizationEditorHandler.languages;
    
    NSMutableArray* langTitles = [NSMutableArray array];
    for (LocalizationEditorLanguage* lang in langs)
    {
        [langTitles addObject:lang.name];
    }
    [popLanguageAdd addItemsWithTitles:langTitles];
}

- (void) updateLanguageSelectionMenu
{
    NSArray* langs = [AppDelegate appDelegate].localizationEditorHandler.activeLanguages;
    
    NSString* currentName = popCurrentLanguage.selectedItem.title;
    
    [popCurrentLanguage removeAllItems];
    
    NSMutableArray* langTitles = [NSMutableArray array];
    for (LocalizationEditorLanguage* lang in langs)
    {
        [langTitles addObject:lang.name];
    }
    
    [popCurrentLanguage addItemsWithTitles:langTitles];
    
    if (currentName)
    {
        [popCurrentLanguage selectItemWithTitle:currentName];
    }
}

- (void) addLanguageColumns
{
    NSArray* langs = [AppDelegate appDelegate].localizationEditorHandler.languages;
    
    for (LocalizationEditorLanguage* lang in langs)
    {
        NSTableColumn* column = [[[NSTableColumn alloc] initWithIdentifier:lang.isoLangCode] autorelease];
        column.width = 200;
        column.maxWidth = 1000;
        column.minWidth = 100;
        [[column headerCell] setStringValue:lang.name];
        
        CCBTextFieldCell* cell = [[[CCBTextFieldCell alloc] init] autorelease];
        [cell setEditable:YES];
        [cell setFont:[NSFont systemFontOfSize:11]];
        [column setDataCell:cell];
        
        [tableTranslations addTableColumn:column];
    }
}

- (void) updateQuickEditLangs
{
    NSArray* activeLangs = [AppDelegate appDelegate].localizationEditorHandler.activeLanguages;
    NSArray* allLangs = [AppDelegate appDelegate].localizationEditorHandler.languages;
    
    for (LocalizationEditorLanguage* lang in allLangs)
    {
        // Find column for language
        NSTableColumn* col = [tableTranslations tableColumnWithIdentifier:lang.isoLangCode];
        
        if ([activeLangs containsObject:lang] && lang.quickEdit)
        {
            [col setHidden:NO];
        }
        else
        {
            [col setHidden:YES];
        }
    }
}

- (LocalizationEditorLanguage*) selectedLanguage
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    NSString* name = [popCurrentLanguage selectedItem].title;
    return [handler getLanguageByName:name];
}

- (void) updateInspector
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1)
    {
        // Disable things
        self.inspectorTextKey = NULL;
        self.inspectorTextComment = NULL;
        self.inspectorTextTranslation = NULL;
    }
    else
    {
        self.inspectorEnabled = YES;
        
        LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
        
        if (translation.key)
        {
            self.inspectorTextKey = [[[NSAttributedString alloc] initWithString:translation.key] autorelease];
        }
        else
        {
            self.inspectorTextKey = NULL;
        }
        
        if (translation.comment)
        {
            self.inspectorTextComment = [[[NSAttributedString alloc] initWithString:translation.comment] autorelease];
        }
        else
        {
            self.inspectorTextComment = NULL;
        }
        
        LocalizationEditorLanguage* lang = [self selectedLanguage];
        NSString* currentTranslation = [translation.translations objectForKey:lang.isoLangCode];
        if (currentTranslation)
        {
            self.inspectorTextTranslation = [[[NSAttributedString alloc] initWithString:currentTranslation] autorelease];
        }
        else
        {
            self.inspectorTextTranslation = NULL;
        }
        if (!lang)
        {
            self.inspectorEnabled = NO;
        }
    }
}

#pragma mark Actions

- (IBAction)pressedAdd:(id)sender
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    LocalizationEditorTranslation* translation = [[LocalizationEditorTranslation alloc] init];
    
    [handler.translations addObject:translation];
    [tableTranslations reloadData];
    
    NSInteger newRow = handler.translations.count -1;
    
    [tableTranslations selectRowIndexes:[NSIndexSet indexSetWithIndex:newRow] byExtendingSelection:NO];
    [tableTranslations editColumn:1 row:newRow withEvent:NULL select:sender];
}

- (IBAction)pressedAddGroup:(id)sender
{}

- (IBAction)selectedAddLanguage:(id)sender
{
    NSString* name = popLanguageAdd.selectedItem.title;
    
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    [handler addActiveLanguage:[handler getLanguageByName:name]];
    
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self updateQuickEditLangs];
    [self updateInspector];
}

- (void)removeLanguagesAtIndexes:(NSIndexSet*)idxs
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    [handler.activeLanguages removeObjectsAtIndexes:idxs];
    
    [tableLanguages reloadData];
    [self updateLanguageSelectionMenu];
    [self updateQuickEditLangs];
    [self updateInspector];
}

- (IBAction)selectedCurrentLanguage:(id)sender
{
    [self updateInspector];
}

- (void)removeTranslationsAtIndexes:(NSIndexSet*)idxs
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    [handler.translations removeObjectsAtIndexes:idxs];
    
    [tableTranslations deselectAll:NULL];
    [tableTranslations reloadData];
    [self updateInspector];
}

#pragma mark Properties for Inspector

- (void) setInspectorTextKey:(NSAttributedString *)inspectorTextKey
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    translation.key = [inspectorTextKey string];
    
    [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:1]];
}

- (NSAttributedString*) inspectorTextKey
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return NULL;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    
    if (!translation.key) return NULL;
    return [[[NSAttributedString alloc] initWithString:translation.key] autorelease];
}

- (void) setInspectorTextComment:(NSAttributedString *)inspectorTextComment
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    translation.comment = [inspectorTextComment string];
    
    [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:2]];
}

- (NSAttributedString*) inspectorTextComment
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return NULL;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    
    if (!translation.comment) return NULL;
    return [[[NSAttributedString alloc] initWithString:translation.comment] autorelease];
}

- (void) setInspectorTextTranslation:(NSAttributedString *)inspectorTextTranslation
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    LocalizationEditorLanguage* lang = [self selectedLanguage];
    
    if (!lang) return;
    
    if (inspectorTextTranslation)
    {
        [translation.translations setObject:[inspectorTextTranslation string] forKey:lang.isoLangCode];
    }
    else
    {
        [translation.translations removeObjectForKey:lang.isoLangCode];
    }
    
    NSInteger col = [tableTranslations columnWithIdentifier:lang.isoLangCode];
    
    [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:col]];
}

- (NSAttributedString*) inspectorTextTranslation
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    NSInteger row = [tableTranslations selectedRow];
    
    if (row == -1) return NULL;
    
    LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
    LocalizationEditorLanguage* lang = [self selectedLanguage];
    NSString* translationStr = [translation.translations objectForKey:lang.isoLangCode];
    
    if (!translationStr) return NULL;
    return [[[NSAttributedString alloc] initWithString:translationStr] autorelease];
}

#pragma mark Table View data provider

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (aTableView == tableLanguages)
    {
        return handler.activeLanguages.count;
    }
    else if (aTableView == tableTranslations)
    {
        return handler.translations.count;
    }
    
    return 0;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (aTableView == tableLanguages)
    {
        if ([aTableColumn.identifier isEqualToString:@"enabled"])
        {
            LocalizationEditorLanguage* lang = [handler.activeLanguages objectAtIndex:rowIndex];
            return [NSNumber numberWithBool:lang.quickEdit];
        }
        else if ([aTableColumn.identifier isEqualToString:@"name"])
        {
            LocalizationEditorLanguage* lang = [handler.activeLanguages objectAtIndex:rowIndex];
            return lang.name;
        }
    }
    else if (aTableView == tableTranslations)
    {
        LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:rowIndex];
        
        if ([aTableColumn.identifier isEqualToString:@"key"])
        {
            return translation.key;
        }
        else if ([aTableColumn.identifier isEqualToString:@"comment"])
        {
            return translation.comment;
        }
        else if ([aTableColumn.identifier isEqualToString:@"warning"])
        {
            if ([translation hasTranslationsForLanguages:handler.activeLanguages])
            {
                // All languages are covered
                return NULL;
            }
            else
            {
                // Some language is missing
                return [NSImage imageNamed:@"editor-warning.png"];
            }
        }
        else
        {
            return [translation.translations objectForKey:aTableColumn.identifier];
        }
    }
    
    return NULL;
}

- (void) tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    if (tableView == tableLanguages)
    {
        if ([tableColumn.identifier isEqualToString:@"enabled"])
        {
            LocalizationEditorLanguage* lang = [handler.activeLanguages objectAtIndex:row];
            lang.quickEdit = [object boolValue];
            [self updateQuickEditLangs];
        }
    }
    else if (tableView == tableTranslations)
    {
        LocalizationEditorTranslation* translation = [handler.translations objectAtIndex:row];
        
        if ([tableColumn.identifier isEqualToString:@"key"])
        {
            // TODO: Check for duplicates
            translation.key = object;
        }
        else if ([tableColumn.identifier isEqualToString:@"comment"])
        {
            translation.comment = object;
        }
        else
        {
            if ([object isKindOfClass:[NSString class]])
            {
                NSString* lang = tableColumn.identifier;
                
                [translation.translations setObject:object forKey:lang];
                [tableTranslations reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:row] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            }
        }
        
        [self updateInspector];
    }
}

#pragma mark Drag and drop

- (id < NSPasteboardWriting >)tableView:(NSTableView *)tableView pasteboardWriterForRow:(NSInteger)row
{
    LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
    
    return [handler.translations objectAtIndex:row];
}

- (NSDragOperation)tableView:(NSTableView *)aTableView validateDrop:(id < NSDraggingInfo >)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropAbove) return NSDragOperationMove;
    return NSDragOperationNone;
}

- (BOOL)tableView:(NSTableView *)aTableView acceptDrop:(id < NSDraggingInfo >)info row:(NSInteger)row dropOperation:(NSTableViewDropOperation)operation
{
    if (operation == NSTableViewDropAbove)
    {
        LocalizationEditorHandler* handler = [AppDelegate appDelegate].localizationEditorHandler;
        NSPasteboard* pb = [info draggingPasteboard];
        
        NSArray* items = [pb propertyListsForType:@"com.cocosbuilder.LocalizationEditorTranslation"];
        if (items.count != 1) return NO;
        
        NSDictionary* dict = [items objectAtIndex:0];
        
        // Find source translation by key
        NSString* key = [dict objectForKey:@"key"];
        LocalizationEditorTranslation* transl = NULL;
        for (LocalizationEditorTranslation* cTransl in handler.translations)
        {
            if ([cTransl.key isEqualToString:key])
            {
                transl = cTransl;
                break;
            }
        }
        
        if (!transl) return NO;
        
        // Move translation to new index
        int oldIndex = [handler.translations indexOfObject:transl];
        int newIndex = row;
        if (newIndex >= oldIndex) newIndex--;
        
        [handler.translations removeObjectAtIndex:oldIndex];
        [handler.translations insertObject:transl atIndex:newIndex];
        
        [tableTranslations reloadData];
        [tableTranslations selectRowIndexes:[NSIndexSet indexSetWithIndex:newIndex] byExtendingSelection:NO];
        
        return YES;
    }
    return NO;
}

#pragma mark Table View delegate

- (void) tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger row = [tableTranslations selectedRow];
    
    self.inspectorEnabled = (row != -1);
    [self updateInspector];
}

@end
