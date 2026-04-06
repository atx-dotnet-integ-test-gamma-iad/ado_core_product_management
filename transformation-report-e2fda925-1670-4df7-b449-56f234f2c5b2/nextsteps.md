# Next Steps

The transformation appears to have completed successfully. There are no build errors present in the solution. Below are steps to validate, test, and deploy your migrated project.

## 1. Verify Target Framework

Open `AdoCore.csproj` and confirm the `<TargetFramework>` element is set to the intended .NET version (e.g., `net8.0` or `net6.0`). For example:

```xml
<PropertyGroup>
  <TargetFramework>net8.0</TargetFramework>
</PropertyGroup>
```

## 2. Restore Dependencies

Run the following command from the solution root to ensure all NuGet packages are restored correctly:

```bash
dotnet restore
```

Review the output for any warnings about deprecated packages or packages that may not fully support the target framework.

## 3. Build the Solution

Perform a clean build to confirm there are no errors or warnings that may have been missed:

```bash
dotnet build --configuration Release
```

Address any warnings that appear, particularly those related to nullable reference types, obsolete APIs, or platform compatibility.

## 4. Run Existing Tests

If the solution contains test projects, execute them to verify that existing functionality has not regressed:

```bash
dotnet test --configuration Release
```

Review the test results and investigate any failures. If tests were previously written against .NET Framework-specific behavior, some may require updates to align with cross-platform .NET behavior.

## 5. Check for Platform-Specific API Usage

Use the .NET Compatibility Analyzer or review the code manually for any APIs that are Windows-specific. These will typically be flagged with a `[SupportedOSPlatform("windows")]` attribute or a `CA1416` analyzer warning. If cross-platform support is required, replace or conditionally compile these APIs.

## 6. Validate Runtime Behavior

Run the application and exercise its core functionality manually or through integration tests. Pay particular attention to:

- File path handling (use `Path.Combine` and avoid hardcoded separators)
- Configuration file loading (e.g., `app.config` vs `appsettings.json`)
- Any reflection-based code that may behave differently under the new runtime

## 7. Review Removed or Changed APIs

Cross-reference the project's usage of any APIs that were removed or significantly changed between .NET Framework and modern .NET. The [.NET Upgrade Assistant compatibility documentation](https://learn.microsoft.com/en-us/dotnet/core/compatibility/) is a useful reference for this.

## 8. Publish the Application

Once validation is complete, publish the application using the following command, adjusting the runtime identifier (`-r`) as needed:

```bash
dotnet publish --configuration Release --output ./publish
```

Verify the contents of the `./publish` directory and confirm the application runs correctly from that location on the target machine.