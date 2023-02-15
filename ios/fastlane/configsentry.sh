          echo $SENTRY_KEY
          pwd
          export ESCAPED_KEYWORD=$(printf '%s\n' "$SENTRY_KEY" | sed -e 's/[]\/$*.^[]/\\&/g');
          sed -i -e "s/<SENTRY_KEY>/$ESCAPED_KEYWORD/g" ../../lib/main.dart
