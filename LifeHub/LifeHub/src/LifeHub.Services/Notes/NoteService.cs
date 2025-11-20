using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Interfaces;
using LifeHub.Core.Models;

namespace LifeHub.Services.Notes;

public class NoteService : INoteService
{
    private readonly List<Note> _notes = new();

    public Task<IList<Note>> GetAllNotesAsync(CancellationToken ct = default)
    {
        return Task.FromResult<IList<Note>>(_notes.OrderByDescending(n => n.ModifiedAt).ToList());
    }

    public Task<Note> CreateNoteAsync(Note note, CancellationToken ct = default)
    {
        _notes.Add(note);
        return Task.FromResult(note);
    }

    public Task<Note> UpdateNoteAsync(Note note, CancellationToken ct = default)
    {
        var existing = _notes.FirstOrDefault(n => n.Id == note.Id);
        if (existing != null)
        {
            _notes.Remove(existing);
            note.ModifiedAt = DateTime.Now;
            _notes.Add(note);
        }
        return Task.FromResult(note);
    }

    public Task DeleteNoteAsync(string noteId, CancellationToken ct = default)
    {
        var existing = _notes.FirstOrDefault(n => n.Id == noteId);
        if (existing != null)
        {
            _notes.Remove(existing);
        }
        return Task.CompletedTask;
    }
}
