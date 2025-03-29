import os
import tensorflow as tf
import argparse
import numpy as np
from tensorflow.keras import layers, models

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--learning_rate', type=float, default=0.01)
    parser.add_argument('--batch_size', type=int, default=32)
    parser.add_argument('--epochs', type=int, default=10)
    parser.add_argument('--model_dir', type=str, default=os.getenv('SM_MODEL_DIR'))
    parser.add_argument('--train', type=str, default=os.getenv('SM_CHANNEL_TRAIN'))
    return parser.parse_args()

def load_data(data_dir):
    """Load and preprocess data"""
    # Load your data here
    # This is a placeholder - replace with your actual data loading logic
    X = np.random.rand(1000, 10)  # Example data
    y = np.random.randint(0, 2, 1000)  # Example labels
    return X, y

def create_model(input_shape, learning_rate):
    """Create and compile the model"""
    model = models.Sequential([
        layers.Dense(64, activation='relu', input_shape=input_shape),
        layers.Dropout(0.2),
        layers.Dense(32, activation='relu'),
        layers.Dropout(0.2),
        layers.Dense(1, activation='sigmoid')
    ])
    
    model.compile(
        optimizer=tf.keras.optimizers.Adam(learning_rate=learning_rate),
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    return model

def main():
    args = parse_args()
    
    # Load data
    X_train, y_train = load_data(args.train)
    
    # Create and train model
    model = create_model(input_shape=(X_train.shape[1],), learning_rate=args.learning_rate)
    
    # Train model
    history = model.fit(
        X_train, y_train,
        batch_size=args.batch_size,
        epochs=args.epochs,
        validation_split=0.2
    )
    
    # Save model
    model.save(os.path.join(args.model_dir, 'model'))
    
    # Log metrics
    for metric_name, metric_value in history.history.items():
        tf.summary.scalar(metric_name, metric_value[-1])

if __name__ == '__main__':
    main() 