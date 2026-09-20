from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


def select_examples(question, training_examples, number_of_examples=8):
    if training_examples.empty:
        raise RuntimeError("The training_set table is empty.")

    documents = (
        training_examples["prompt"]
        + " "
        + training_examples["tags"].str.replace(",", " ")
    ).tolist()

    vectors = TfidfVectorizer(stop_words="english").fit_transform(
        documents + [question]
    )

    scores = cosine_similarity(
        vectors[-1],
        vectors[:-1],
    ).ravel()

    number_to_select = min(number_of_examples, len(training_examples))
    selected_rows = scores.argsort()[::-1][:number_to_select]

    examples = []

    for row_number in selected_rows:
        row = training_examples.iloc[row_number]
        examples.append(
            f"Prompt: {row['prompt']}\n"
            f"Tags: {row['tags']}\n"
            f"SQL: {row['sql_text']}"
        )

    return "\n\n".join(examples)
