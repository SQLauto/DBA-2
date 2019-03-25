using System;
using System.Collections;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Deployment.Common.Helpers;
// ReSharper disable PossibleMultipleEnumeration

namespace Deployment.Common
{
    /// <summary>
    ///
    /// </summary>
    public static class CollectionExtensions
    {
        /// <summary>
        /// Returns a delimited <see cref="System.String"/> that represents each value of the collection
        /// <example>
        /// Calling on a list of enum object,
        /// Calling convention: IEnumerable{T} xxx.ToString(",")
        /// </example>
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="source">The source.</param>
        /// <param name="separator">The separator.</param>
        /// <returns>
        /// A <see cref="System.String"/> that represents this instance.
        /// </returns>
        public static string ToString<T>(this IEnumerable<T> source, string separator = ",") {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNullOrEmpty(separator, "separator", "Separator can not be null or empty.");

            var array =
                source.Where(item => item != null).Select(item => item.ToString())
                .ToArray();

            return string.Join(separator, array);
        }

        /// <summary>
        /// Adds an <see cref="IEnumerable{T}"/> of items to an <see cref="ICollection{T}"/>
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="source">The source.</param>
        /// <param name="items">The items.</param>
        public static void AddRange<T>(this ICollection<T> source, IEnumerable<T> items) {

            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNull(items, "items", "Items can not be null.");

            var list = source as List<T>;

            if(list != null) {
                list.AddRange(items);
            }
            else {
                foreach(var item in items) {
                    source.Add(item);
                }
            }
        }

        /// <summary>
        /// Returns true if the input sequence was null or empty, false otherwise.
        /// </summary>
        /// When you use Count() on an IEnumerable{T} the whole list needs to be iterated before count can be called.
        /// Using this method, we can determine if the IEnumeable{T} is empty by checking the Enumerator.MoveNext method
        /// <typeparam name="TSource">The type of the source sequence.</typeparam>
        /// <param name="source">The source sequence.</param>
        /// <returns>
        /// 	<c>true</c> if the source sequence is empty; otherwise, <c>false</c>.
        /// </returns>
        public static bool IsNullOrEmpty<TSource>(this IEnumerable<TSource> source) {
            if(source == null)
                return true;

            //surprisingly, .net does not do this in the Any method and just calls GetEnumerator and tries to excute a single loop
            var collection = source as ICollection<TSource>;

            if(collection != null) {
                return collection.Count == 0;
            }

            return !source.Any();
        }

        /// <summary>
        /// Returns true if the input sequence was empty, false otherwise.
        /// </summary>
        /// When you use Count() on an IEnumerable{T} the whole list needs to be iterated before count can be called.
        /// Using this method, we can determine if the IEnumeable{T} is empty by checking the Enumerator.MoveNext method
        /// <typeparam name="TSource">The type of the source sequence.</typeparam>
        /// <param name="source">The source sequence.</param>
        /// <returns>
        /// 	<c>true</c> if the source sequence is empty; otherwise, <c>false</c>.
        /// </returns>
        public static bool IsEmpty<TSource>(this IEnumerable<TSource> source) {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");

            //surprisingly, .net does not do this in the Any method and just calls GetEnumerator and tries to excute a single loop
            var collection = source as ICollection<TSource>;

            if(collection != null) {
                return collection.Count == 0;
            }

            return !source.Any();
        }

        /// <summary>
        /// A more efficient way of determine wether the item count of an IEnumerable{T} is equal to a given value.
        /// </summary>
        /// <remarks>
        /// When you use Count() on an IEnumerable{T} the whole list needs to be iterated before count can be called.
        /// Using this method, iteration can stop as soon as we get a false value, so the whole list does not need to be iterated.
        /// </remarks>
        /// <typeparam name="TSource">The type of the source.</typeparam>
        /// <param name="source">The source.</param>
        /// <param name="value">The value.</param>
        /// <returns></returns>
        public static bool CountEqualTo<TSource>(this IEnumerable<TSource> source, int value)
        {

            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertIntValue(0, item => value < item, "value", "Value under test must be zero or greater.");

            //if our IEnumerable<TSource> can be cast to ICollection<TSource> we can make use
            //of the count property of collection as this is efficient.
            var collection = source as ICollection<TSource>;

            if (collection != null)
            {
                return collection.Count == value;
            }

            var counter = 0;

            //Iterate over the items, counting as we go.  At each iteration we check the counter
            //value against out test value, and if it is greater, then count not equal, so retun false;
            using (var enumerator = source.GetEnumerator())
            {
                while (enumerator.MoveNext())
                {
                    counter++;

                    if (counter > value)
                        return false;
                }

                //if here it means that either we did not have an enumerator
                //or counter vallue was not greater that out test value, so now simple compare results.
                return counter == value;
            }
        }

        /// <summary>
        /// A more efficient way of determine wether the item count of an IEnumerable{T} is greater than a given value.
        /// </summary>
        /// <remarks>
        /// When you use Count() on an IEnumerable{T} the whole list needs to be iterated before count can be called.
        /// Using this method, iteration can stop as soon as the item count is greater than out test value
        /// so the whole list does not need to be iterated.
        /// </remarks>
        /// <typeparam name="TSource">The type of the source.</typeparam>
        /// <param name="source">The source.</param>
        /// <param name="value">The value.</param>
        /// <returns></returns>
        public static bool CountGreaterThan<TSource>(this IEnumerable<TSource> source, int value)
        {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertIntValue(0, item => value < item, "value", "Value under test must be zero or greater.");

            //if our IEnumerable<TSource> can be cast to ICollection<TSource> we can make use
            //of the count property of collection as this is efficient.
            var collection = source as ICollection<TSource>;

            if (collection != null)
            {
                return collection.Count > value;
            }

            var counter = 0;

            //Iterate over the items, counting as we go.  Continue to count all the time we have an iterator
            using (var enumerator = source.GetEnumerator())
            {
                while (enumerator.MoveNext())
                {
                    counter++;
                    //as soon as our counter is greater than test value, we can return true
                    if (counter > value)
                        return true;
                }

                //if here out counter can not be greater than our test value, therefore return false;
                return false;
            }
        }

        public static bool CountGreaterThan<TSource>(this IEnumerable<TSource> source, Func<TSource, bool> filter, int value)
        {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNull(filter, "filter", "Filter can not be null.");
            ArgumentHelper.AssertIntValue(0, item => value < item, "value", "Value under test must be zero or greater.");

            var filtered = source.Where(filter);

            return filtered.CountGreaterThan(value);
        }

        /// <summary>
        /// ForEach extension method for allowing the calling or ForEach on a LINQ query.
        /// </summary>
        /// <typeparam name="T"></typeparam>
        /// <param name="source">The source.</param>
        /// <param name="func">The func.</param>
        public static void ForEach<T>(this IEnumerable<T> source, Action<T> func) {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNull(func, "func", "Action delegate can not be null.");

            foreach(var item in source)
                func(item);
        }

        /// <summary>
        /// Walks two sequences simultaneously and performs an action on the pairs of values.
        /// </summary>
        /// <typeparam name="T1">The type of the first sequence.</typeparam>
        /// <typeparam name="T2">The type of the second sequence.</typeparam>
        /// <param name="source1">The type of elements the first sequence.</param>
        /// <param name="source2">The type of elements in the second sequence.</param>
        /// <param name="func">The action to perform.</param>
        public static void ForEach<T1, T2>(this IEnumerable<T1> source1, IEnumerable<T2> source2, Action<T1, T2> func) {

            ArgumentHelper.AssertNotNull("source1", "Source1 can not be null.");
            ArgumentHelper.AssertNotNull("source2", "Source2 can not be null.");
            ArgumentHelper.AssertNotNull(func, "func", "Action delegate can not be null.");

            using(var enumerator1 = source1.GetEnumerator()) {
                using(var enumerator2 = source2.GetEnumerator()) {
                    while(enumerator1.MoveNext() && enumerator2.MoveNext()) {
                        func(enumerator1.Current, enumerator2.Current);
                    }
                }
            }
        }

        /// <summary>
        /// ForEach extension method for iterating over the keys of an IDictionary object
        /// </summary>
        /// <typeparam name="TKey">The type of the key.</typeparam>
        /// <typeparam name="TValue">The type of the value.</typeparam>
        /// <param name="source">The source.</param>
        /// <param name="func">The func.</param>
        public static void ForEachKey<TKey, TValue>(this IDictionary<TKey, TValue> source, Action<TKey> func) {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNull(func, "func", "Action delegate can not be null.");

            foreach(var item in source.Keys)
                func(item);
        }

        /// <summary>
        /// ForEach extension method for iterating over the values of an IDictionary object
        /// </summary>
        /// <typeparam name="TKey">The type of the key.</typeparam>
        /// <typeparam name="TValue">The type of the value.</typeparam>
        /// <param name="source">The source.</param>
        /// <param name="func">The func.</param>
        public static void ForEachValue<TKey, TValue>(this IDictionary<TKey, TValue> source, Action<TValue> func) {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNull(func, "func", "Action delegate can not be null.");

            foreach(var item in source.Values)
                func(item);
        }

        public static Task ForEachAsync<T>(this IEnumerable<T> source, Func<T, Task> body, int partitionCount = 1)
        {
            ArgumentHelper.AssertNotNull(source, "source", "Source can not be null.");
            ArgumentHelper.AssertNotNull(body, "body", "Action delegate can not be null.");

            return Task.WhenAll(
                from partition in Partitioner.Create(source).GetPartitions(partitionCount)
                select Task.Run(async delegate {
                    using (partition)
                        while (partition.MoveNext())
                            await body(partition.Current);
                }));
        }

        public static IDictionary<TKey, TValue> ToDictionary<TKey, TValue>(this Hashtable table)
        {
            return table
              .Cast<DictionaryEntry>().OrderBy(k => k.Key)
              .ToDictionary(kvp => (TKey)kvp.Key, kvp => (TValue)kvp.Value);
        }

        public static IEnumerable<T> GetDuplicates<T, TKey>(this IEnumerable<T> source,Func<T,TKey> keySelector)
        {
             return source.GroupBy(keySelector)
                .Where(g => g.CountGreaterThan(1))
                .SelectMany(g => g.Select(a => a));
        }
    }
}