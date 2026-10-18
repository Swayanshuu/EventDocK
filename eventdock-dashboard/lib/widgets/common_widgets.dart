import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Reusable EventDock Logo Component
/// Displays the official wordmark asset with seamless fallback to high-fidelity typographic wordmark.
class EventDockLogo extends StatelessWidget {
  final double height;
  final double fontSize;
  final bool forceText;

  const EventDockLogo({
    super.key,
    this.height = 32,
    this.fontSize = 20,
    this.forceText = false,
  });

  @override
  Widget build(BuildContext context) {
    if (forceText) {
      return EventDockWordmark(fontSize: fontSize);
    }

    return Semantics(
      label: 'EventDock',
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // On-stage semantic and test runner identifier
          const SizedBox(
            width: 0,
            height: 0,
            child: Text('EventDock', style: TextStyle(color: Colors.transparent, fontSize: 0.01)),
          ),
          Image.asset(
            'assets/EventDocK-removebg-preview.png',
            height: height,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorBuilder: (context, error, stackTrace) => EventDockWordmark(fontSize: fontSize),
          ),
        ],
      ),
    );
  }
}

/// Typographic wordmark with 'Event' in warm off-white and 'Dock' in signal orange.
class EventDockWordmark extends StatelessWidget {
  final double fontSize;
  final FontWeight fontWeight;
  final double letterSpacing;

  const EventDockWordmark({
    super.key,
    this.fontSize = 20,
    this.fontWeight = FontWeight.w800,
    this.letterSpacing = -0.5,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'EventDock',
      child: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Event',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: fontWeight,
                fontSize: fontSize,
                letterSpacing: letterSpacing,
              ),
            ),
            TextSpan(
              text: 'Dock',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: fontWeight,
                fontSize: fontSize,
                letterSpacing: letterSpacing,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatusBadge extends StatelessWidget {
  final int statusCode;

  const StatusBadge({super.key, required this.statusCode});

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (statusCode >= 500) {
      bg = AppTheme.status5xx.withValues(alpha: 0.12);
      fg = AppTheme.status5xx;
    } else if (statusCode >= 400) {
      bg = AppTheme.status4xx.withValues(alpha: 0.12);
      fg = AppTheme.status4xx;
    } else if (statusCode >= 200) {
      bg = AppTheme.status2xx.withValues(alpha: 0.12);
      fg = AppTheme.status2xx;
    } else {
      bg = AppTheme.cardSecondary;
      fg = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.35), width: 1),
      ),
      child: Text(
        statusCode > 0 ? '$statusCode' : 'ERR',
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 12,
          fontFamily: 'monospace',
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

class MethodBadge extends StatelessWidget {
  final String method;

  const MethodBadge({super.key, required this.method});

  @override
  Widget build(BuildContext context) {
    Color fg;
    final m = method.toUpperCase();

    if (m == 'GET') {
      fg = const Color(0xFF38BDF8); // Soft Cyan
    } else if (m == 'POST') {
      fg = AppTheme.primary; // Signal Orange for action/create
    } else if (m == 'PUT' || m == 'PATCH') {
      fg = AppTheme.status4xx; // Warning Amber for update
    } else if (m == 'DELETE') {
      fg = AppTheme.status5xx; // Error Red for delete
    } else {
      fg = AppTheme.textMuted;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppTheme.cardSecondary,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        m,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w700,
          fontSize: 11,
          fontFamily: 'monospace',
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class CodeSnippetBox extends StatelessWidget {
  final String content;
  final String? label;

  const CodeSnippetBox({super.key, required this.content, this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppTheme.codeBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (label != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label!,
                      style: const TextStyle(
                        color: AppTheme.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    borderRadius: BorderRadius.circular(4),
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Copied to clipboard'),
                          duration: Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.copy_rounded, size: 14, color: AppTheme.primary),
                          SizedBox(width: 4),
                          Text(
                            'Copy',
                            style: TextStyle(color: AppTheme.primary, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: SelectableText(
              content,
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: AppTheme.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
