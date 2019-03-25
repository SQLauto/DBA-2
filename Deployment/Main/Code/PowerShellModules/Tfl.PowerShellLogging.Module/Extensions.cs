using System;
using System.Collections.Generic;

namespace TFL.PowerShell.Logging
{
    public static class Extensions
    {
        /// <summary>
        /// ForEach extension method for allowing the calling or ForEach on a LINQ query.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="source">The source.</param>
        /// <param name="func">The func.</param>
        /// <param name="callback"></param>
        public static void ForEach<T>(this IEnumerable<T> source, Action<T> func, Action<T> callback = null)
        {
            if (source == null)
                throw new ArgumentNullException(nameof(source), "Source cannot be null.");
            if (source == null)
                throw new ArgumentNullException(nameof(func), "Func cannot be null.");

            foreach (var item in source)
            {
                func(item);
                callback?.Invoke(item);
            }
        }
    }
}