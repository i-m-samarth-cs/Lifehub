using System.Collections.Generic;
using System.Threading;
using System.Threading.Tasks;
using LifeHub.Core.Models;

namespace LifeHub.Core.Interfaces;

public interface INoteService
{
    Task<IList<Note>> GetAllNotesAsync(CancellationToken ct = default);
    Task<Note> CreateNoteAsync(Note note, CancellationToken ct = default);
    Task<Note> UpdateNoteAsync(Note note, CancellationToken ct = default);
    Task DeleteNoteAsync(string noteId, CancellationToken ct = default);
}
